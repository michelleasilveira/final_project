library(tidyverse)
library(janitor)
library(tidymodels)
library(plumber)

tidymodels_prefer()

#-----------------------------#
#  Load data & fit final model
#-----------------------------#

diabetes <- readr::read_csv(
  "data/diabetes_binary_health_indicators_BRFSS2015.csv"
) |>
  clean_names() |>
  mutate(
    diabetes_binary = factor(diabetes_binary,
                             levels = c(0, 1),
                             labels = c("No", "Yes"))
  )

diabetes_rec <- recipe(
  diabetes_binary ~ high_bp + bmi + smoker + phys_activity +
    gen_hlth + age,
  data = diabetes
) |>
  step_impute_median(bmi) |>
  step_impute_mode(all_nominal_predictors())

# >>> Replace mtry & min_n with your tuned values from Modeling.qmd <<<
final_rf_spec <- rand_forest(
  mtry  = 4,
  min_n = 10,
  trees = 500
) |>
  set_engine("ranger", importance = "impurity") |>
  set_mode("classification")

final_rf_wf <- workflow() |>
  add_recipe(diabetes_rec) |>
  add_model(final_rf_spec)

final_rf_fit <- final_rf_wf |>
  fit(diabetes)

# Defaults for /pred endpoint (rough – you can refine using your EDA)
default_bmi   <- mean(diabetes$bmi, na.rm = TRUE)
default_age   <- names(sort(table(diabetes$age), decreasing = TRUE))[1]
default_bp    <- names(sort(table(diabetes$high_bp), decreasing = TRUE))[1]
default_smoke <- names(sort(table(diabetes$smoker), decreasing = TRUE))[1]
default_phys  <- names(sort(table(diabetes$phys_activity), decreasing = TRUE))[1]
default_gen   <- names(sort(table(diabetes$gen_hlth), decreasing = TRUE))[1]

#-----------------------------#
#  /info endpoint
#-----------------------------#

#* @get /info
function() {
  list(
    name = "YOUR NAME HERE",
    github_pages = "https://YOUR-USER.github.io/YOUR-REPO/"
  )
}

#-----------------------------#
#  /pred endpoint
#-----------------------------#

#* Predict probability of diabetes = "Yes"
#* @param high_bp High blood pressure (0/1 coded as "0" or "1")
#* @param bmi Body Mass Index
#* @param smoker Smoker status (0/1)
#* @param phys_activity Physical activity (0/1)
#* @param gen_hlth General health category (like 1–5)
#* @param age Age category code
#* @get /pred
function(
    high_bp      = default_bp,
    bmi          = default_bmi,
    smoker       = default_smoke,
    phys_activity= default_phys,
    gen_hlth     = default_gen,
    age          = default_age
) {
  
  new_obs <- tibble(
    high_bp       = as.numeric(high_bp),
    bmi           = as.numeric(bmi),
    smoker        = as.numeric(smoker),
    phys_activity = as.numeric(phys_activity),
    gen_hlth      = as.numeric(gen_hlth),
    age           = as.numeric(age)
  )
  
  prob <- predict(final_rf_fit, new_obs, type = "prob")$.pred_Yes
  
  list(
    prob_diabetes_yes = prob
  )
}

# Example calls (for the assignment, in comments):
# http://localhost:8000/pred?bmi=30&high_bp=1&smoker=0&phys_activity=1&gen_hlth=3&age=9
# http://localhost:8000/pred?bmi=25&high_bp=0&smoker=0&phys_activity=1&gen_hlth=2&age=7
# http://localhost:8000/pred?bmi=35&high_bp=1&smoker=1&phys_activity=0&gen_hlth=4&age=11

#-----------------------------#
#  /confusion endpoint
#-----------------------------#

#* Plot confusion matrix for the final model
#* @serializer png
#* @get /confusion
function() {
  
  preds <- predict(final_rf_fit, diabetes, type = "class") |>
    bind_cols(diabetes |> select(diabetes_binary))
  
  cm <- table(
    Predicted = preds$.pred_class,
    Actual    = preds$diabetes_binary
  )
  
  op <- par(mar = c(5,5,4,2))
  on.exit(par(op))
  
  mosaicplot(cm, main = "Confusion Matrix – Random Forest")
}
