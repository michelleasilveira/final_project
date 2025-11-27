library(plumber)
library(tidymodels)
library(jsonlite)
library(dplyr)

tidymodels_prefer()

# load champion model (classification tree workflow)
tree_model <- readRDS("model/final_tree_fit.rds")

# helper: make new data look like training data
clean_new_data <- function(df) {
  age_labels <- c(
    "18–24", "25–29", "30–34", "35–39",
    "40–44", "45–49", "50–54", "55–59",
    "60–64", "65–69", "70–74", "75–79", "80+"
  )
  
  df %>%
    mutate(
      # Sex coded 0/1 in input
      Sex = factor(Sex,
                   levels = c(0, 1),
                   labels = c("Female", "Male")),
      # GenHlth coded 1–5 in input
      GenHlth = factor(
        GenHlth,
        levels = 1:5,
        labels = c("Excellent", "Very_good", "Good", "Fair", "Poor"),
        ordered = TRUE
      ),
      # Age coded 1–13 in input
      Age = factor(
        Age,
        levels = 1:13,
        labels = age_labels,
        ordered = TRUE
      )
    )
}

#* @apiTitle Diabetes Classification Tree API

#* Predict probability of diabetes (binary outcome)
#* @post /predict
#* @param body:json The input JSON containing predictor values
function(body) {
  
  # 1) read JSON body into a tibble
  input_list <- jsonlite::fromJSON(body)
  new_obs <- tibble::as_tibble(input_list)
  
  # 2) apply same factor coding as training data
  new_clean <- clean_new_data(new_obs)
  
  # 3) use the fitted workflow to get class probabilities
  preds <- predict(tree_model, new_clean, type = "prob")
  
  # 4) return probability of the "Diabetes" class
  list(
    diabetes_probability = preds$.pred_Diabetes
  )
}
