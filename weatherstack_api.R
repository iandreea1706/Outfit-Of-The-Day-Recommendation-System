# Loading necessary libraries
# For making HTTP request
library(httr)
#  For parsing JSON responses
library(jsonlite)
# For using the pipe operator - had problems in Bash
library(magrittr)  

# Reading environment variables from the .Renviron file for Bash again
readRenviron(".Renviron")

# Retrieving API key from environment variable
api_key <- Sys.getenv("YOUR_ACCESS_KEY")

# Checking if the API key is missing -> stop execution
if (api_key == "") {
  stop("API key not found. Please ensure YOUR_ACCESS_KEY is set as an environment variable.")
}

# Defining Weatherstack API endpoint and query
url <- "http://api.weatherstack.com/current"
params <- list(
  access_key = api_key,
  query = "London"
)

# Making the GET request
response <- GET(url, query = params)

# Handling HTTP errors -> stopping execution if error
if (response$status_code != 200) {
  stop(paste("Failed to fetch data:", response$status_code, response$reason))
}

# Parsing the response from JSON
weather_data <- content(response, as = "text") %>% fromJSON(flatten = TRUE)

# Extracting weather information that we will use
current_temperature <- weather_data$current$temperature
weather_descriptions <- weather_data$current$weather_descriptions
print(paste("Current temperature:", current_temperature, "°C"))
print(paste("Weather description:", paste(weather_descriptions, collapse = ", ")))

# Saveing the weather data for further use
saveRDS(weather_data, "weather_data.rds")

# Confirmation message
cat("Weather data saved to 'weather_data.rds'\n")
