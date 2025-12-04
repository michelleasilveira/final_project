# Diabetes Health Indicators – Predictive Modeling Project

## Project Overview

This project builds and deploys a predictive model for diabetes classification using the **Diabetes Health Indicators** dataset from the BRFSS 2015 survey. The project includes:

- **Exploratory Data Analysis (EDA)** - Understanding the data and identifying key predictors
- **Predictive Modeling** - Building and comparing classification tree and random forest models
- **REST API Deployment** - Serving the champion model via a Dockerized Plumber API

## Project Structure

```
final_project/
├── _quarto.yml                  # Quarto project configuration
├── .gitignore                   # Git ignore file
├── .Rhistory                    # R history
├── api.R                        # Plumber API definition
├── Dockerfile                   # Docker configuration
├── EDA.qmd                      # Exploratory Data Analysis report
├── Modeling.qmd                 # Modeling report
├── Modeling.markdown            # Modeling markdown output
├── final_project.Rproj          # RStudio project file
├── LICENSE                      # Project license
├── README.md                    # This file (project documentation)
├── data/                        # Raw data folder
│   └── diabetes_binary_health_indicators_BRFSS2015.csv
├── docs/                        # Rendered HTML reports (website output)
│   ├── EDA.html
│   └── Modeling.html
└── model/                       # Trained model artifacts
    ├── final_tree_fit.rds       # Trained classification tree model
    └── recipe.rds               # Preprocessing recipe
```

**Note:** The Docker image `diabetes-tree-api.tar` should be placed in the project root directory.

## Model Details

- **Model Type**: Classification Tree (Decision Tree)
- **Engine**: rpart
- **Outcome**: Binary diabetes classification (No_diabetes vs Diabetes)
- **Predictors**: HighBP, HighChol, BMI, Smoker, PhysActivity, GenHlth, DiffWalk, Age, Sex, Income
- **Tuning**: 5-fold cross-validation using log-loss metric
- **Champion Model**: Classification tree selected based on lowest test set log-loss

## Running the API from Docker Image

### Prerequisites

- Docker installed on your system
- The `diabetes-tree-api.tar` file

### Step 1: Load the Docker Image

```bash
# Load the image from the tar file
docker load -i diabetes-tree-api.tar

# Verify the image was loaded
docker images
```

You should see an image named `diabetes-tree-api`.

### Step 2: Run the Container

```bash
# Run the container
docker run -d -p 8000:8000 --name diabetes-prediction diabetes-tree-api

# Check that the container is running
docker ps
```

The API will be available at `http://localhost:8000`

### Step 3: Test the API

**Health Check:**
```bash
curl http://localhost:8000/health
```

**Make a Prediction:**
```bash
curl -X POST "http://localhost:8000/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "HighBP": 1,
    "HighChol": 1,
    "BMI": 32,
    "Smoker": 1,
    "PhysActivity": 0,
    "GenHlth": 4,
    "DiffWalk": 1,
    "Age": 30,
    "Sex": 0,
    "Income": 3
  }'
```

**Expected Response:**
```json
{
  "prediction": "Diabetes",
  "diabetes_probability": 0.6234,
  "no_diabetes_probability": 0.3766
}
```

### Step 4: Stop and Remove the Container

```bash
# Stop the container
docker stop diabetes-prediction

# Remove the container
docker rm diabetes-prediction
```

## API Endpoints

### `/health` - Health Check
**Method:** GET

**Example:**
```bash
curl http://localhost:8000/health
```

**Response:**
```json
{
  "status": "healthy",
  "model": "classification_tree",
  "timestamp": "2025-01-15T10:30:00Z"
}
```

### `/predict` - Single Prediction
**Method:** POST

**Content-Type:** application/json

**Request Body:**
```json
{
  "HighBP": 1,
  "HighChol": 1,
  "BMI": 32,
  "Smoker": 1,
  "PhysActivity": 0,
  "GenHlth": 4,
  "DiffWalk": 1,
  "Age": 30,
  "Sex": 0,
  "Income": 3
}
```

**Response:**
```json
{
  "prediction": "Diabetes",
  "diabetes_probability": 0.6234,
  "no_diabetes_probability": 0.3766
}
```

## Input Parameters

| Parameter | Type | Values | Description |
|-----------|------|--------|-------------|
| `HighBP` | Integer | 0, 1 | High blood pressure (0=No, 1=Yes) |
| `HighChol` | Integer | 0, 1 | High cholesterol (0=No, 1=Yes) |
| `BMI` | Numeric | > 0 | Body Mass Index |
| `Smoker` | Integer | 0, 1 | Has smoked at least 100 cigarettes (0=No, 1=Yes) |
| `PhysActivity` | Integer | 0, 1 | Physical activity in past 30 days (0=No, 1=Yes) |
| `GenHlth` | Integer | 1-5 | General health (1=Excellent, 2=Very good, 3=Good, 4=Fair, 5=Poor) |
| `DiffWalk` | Integer | 0, 1 | Difficulty walking or climbing stairs (0=No, 1=Yes) |
| `Age` | Integer | 1-13 | Age category (1=18-24, 2=25-29, ..., 13=80+) |
| `Sex` | Integer | 0, 1 | Sex (0=Female, 1=Male) |
| `Income` | Integer | 1-8 | Income level (1=Less than $10,000, 8=$75,000 or more) |

## Testing Examples

### Using cURL

```bash
# Example 1: High-risk individual
curl -X POST "http://localhost:8000/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "HighBP": 1,
    "HighChol": 1,
    "BMI": 32,
    "Smoker": 1,
    "PhysActivity": 0,
    "GenHlth": 4,
    "DiffWalk": 1,
    "Age": 30,
    "Sex": 0,
    "Income": 3
  }'

# Example 2: Low-risk individual
curl -X POST "http://localhost:8000/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "HighBP": 0,
    "HighChol": 0,
    "BMI": 22,
    "Smoker": 0,
    "PhysActivity": 1,
    "GenHlth": 1,
    "DiffWalk": 0,
    "Age": 5,
    "Sex": 1,
    "Income": 7
  }'
```

### Using Python

```python
import requests
import json

url = "http://localhost:8000/predict"

# Input data
data = {
    "HighBP": 1,
    "HighChol": 1,
    "BMI": 32,
    "Smoker": 1,
    "PhysActivity": 0,
    "GenHlth": 4,
    "DiffWalk": 1,
    "Age": 30,
    "Sex": 0,
    "Income": 3
}

# Make prediction
response = requests.post(url, json=data)
result = response.json()

print(f"Prediction: {result['prediction']}")
print(f"Diabetes Probability: {result['diabetes_probability']}")
print(f"No Diabetes Probability: {result['no_diabetes_probability']}")
```

### Using R

```r
library(httr)
library(jsonlite)

url <- "http://localhost:8000/predict"

# Input data
data <- list(
  HighBP = 1,
  HighChol = 1,
  BMI = 32,
  Smoker = 1,
  PhysActivity = 0,
  GenHlth = 4,
  DiffWalk = 1,
  Age = 30,
  Sex = 0,
  Income = 3
)

# Make prediction
response <- POST(
  url,
  body = toJSON(data, auto_unbox = TRUE),
  content_type_json()
)

result <- content(response)
print(result)
```

### Using Postman

1. Open Postman
2. Create a new **POST** request
3. URL: `http://localhost:8000/predict`
4. Headers: Set `Content-Type` to `application/json`
5. Body: Select **raw** and **JSON**, then paste:
```json
{
  "HighBP": 1,
  "HighChol": 1,
  "BMI": 32,
  "Smoker": 1,
  "PhysActivity": 0,
  "GenHlth": 4,
  "DiffWalk": 1,
  "Age": 30,
  "Sex": 0,
  "Income": 3
}
```
6. Click **Send**

## Troubleshooting

### Container won't start
```bash
# Check container logs
docker logs diabetes-prediction

# Check if port 8000 is already in use
# On Linux/Mac:
lsof -i :8000

# On Windows:
netstat -ano | findstr :8000
```

### Cannot connect to API
```bash
# Verify container is running
docker ps

# Check container health
docker inspect diabetes-prediction

# Try accessing from inside the container
docker exec -it diabetes-prediction curl http://localhost:8000/health
```

### Image not found after loading
```bash
# List all images
docker images

# The image name might be different - use the correct IMAGE ID or name
docker run -d -p 8000:8000 --name diabetes-prediction <IMAGE_ID>
```

## Docker Management Commands

```bash
# View running containers
docker ps

# View all containers (including stopped)
docker ps -a

# View logs
docker logs diabetes-prediction

# Follow logs in real-time
docker logs -f diabetes-prediction

# Stop container
docker stop diabetes-prediction

# Start stopped container
docker start diabetes-prediction

# Remove container
docker rm diabetes-prediction

# Remove image (after stopping/removing container)
docker rmi diabetes-tree-api
```

## Project Reports

View the rendered HTML reports in the `docs/` folder:

- **EDA Report**: `docs/EDA.html` - Exploratory data analysis with visualizations
- **Modeling Report**: `docs/Modeling.html` - Model development, tuning, and evaluation

To view the reports, open the HTML files in your web browser or visit the project website (if deployed).

## Dataset Information

**Source**: Behavioral Risk Factor Surveillance System (BRFSS) 2015

**Size**: 253,680 survey responses

**Target Variable**: 
- 0 = No diabetes or prediabetes
- 1 = Diabetes

**Class Distribution**: Imbalanced dataset with fewer diabetes cases

## Model Performance

The champion classification tree model was selected based on:
- Lowest log-loss on test set
- Good balance of interpretability and predictive performance
- 5-fold cross-validation with stratified sampling

Performance metrics available in the `diabetes-modeling.html` report.

## Author

Michelle A Silveira

## License

This project is for educational and demonstration purposes.