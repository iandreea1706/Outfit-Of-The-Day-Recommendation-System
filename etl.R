# Loading necessary libraries
# For connecting to and managing SQLite databases
library(RSQLite)
library(dplyr)

# Defining the database file name
db_file <- "closet.db"

# Reading the raw product data from csv
products <- read.csv("products_raw.csv", stringsAsFactors = FALSE)

# Data Cleaning
# Removing rows with missing values
# Ensuring 'category' has valid values
products_clean <- products %>%
  filter(!is.na(name), !is.na(category), !is.na(image_path))

# Printing a summary of cleaned data
print(paste("Number of products after cleaning:", nrow(products_clean)))

# Connecting to SQLite Database
conn <- dbConnect(SQLite(), dbname = db_file)

# Creating the 'closet' table if it doesn't exist
dbExecute(conn, "
  CREATE TABLE IF NOT EXISTS closet (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT,
    category TEXT,
    image_path TEXT
  )
")

# Deleting all records in the closet table so we don't have duplicates (useful only after the second run)
dbExecute(conn, "DELETE FROM closet")

# Inserting the cleaned data into the 'closet' table
dbWriteTable(conn, "closet", products_clean, append = TRUE, row.names = FALSE)

# For checking:
# Viewing the contents of the 'closet' table
closet_data <- dbGetQuery(conn, "SELECT * FROM closet")
print("Contents of the 'closet' table:")
closet_data

# Disconnecting from the database
dbDisconnect(conn)

# Confirmation message
cat("ETL process completed. Data has been inserted into 'closet.db'\n")





