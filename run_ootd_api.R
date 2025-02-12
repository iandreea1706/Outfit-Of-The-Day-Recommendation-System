library(plumber)

# Loading the API
r <- plumb("ootd_api.R")

# Running the API on port 8000
r$run(port = 8000)




