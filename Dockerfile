FROM rocker/plumber

WORKDIR /app

COPY . /app

RUN R -e "install.packages(c('tidyverse','janitor','lubridate','skimr','GGally','tidymodels','plumber'))"

EXPOSE 8000

CMD ["R", "-e", "pr <- plumber::plumb('api.R'); pr$run(host='0.0.0.0', port=8000)"]
