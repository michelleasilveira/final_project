FROM rocker/r-ver:4.3.2

# System dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install R packages
RUN R -e "install.packages(c('tidyverse','tidymodels','plumber','jsonlite','janitor','lubridate','rpart','ranger','dplyr'))"

# Copy project files into the image
WORKDIR /app
COPY . .

# Expose plumber port
EXPOSE 8000

# Run the API when the container starts
CMD ["R", "-e", "pr <- plumber::plumb('api.R'); pr$run(host='0.0.0.0', port=8000)"]
