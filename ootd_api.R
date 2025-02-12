# Load necessary libraries
library(plumber)
library(RSQLite)
library(magick)
library(png)
library(grid)

# Helper function to generate unique outfits - THE RECOMMENDATION LOGIC BASED ON THE TEMPERATURE AND WEATHER DESCRIPTION

generate_outfit <- function(conn, temperature, weather_desc, used_items) {
  outfit <- list()
  
  if (temperature > 25) {
    outfit$top <- dbGetQuery(conn, sprintf("SELECT * FROM closet WHERE category = 't_shirts' AND id NOT IN (%s) ORDER BY RANDOM() LIMIT 1", paste(used_items, collapse = ",")))
    outfit$bottom <- dbGetQuery(conn, sprintf("SELECT * FROM closet WHERE (category = 'skirts' OR category = 'shorts') AND id NOT IN (%s) ORDER BY RANDOM() LIMIT 1", paste(used_items, collapse = ",")))
    outfit$shoes <- dbGetQuery(conn, sprintf("SELECT * FROM closet WHERE category = 'sandals' AND id NOT IN (%s) ORDER BY RANDOM() LIMIT 1", paste(used_items, collapse = ",")))
    outfit$bag <- dbGetQuery(conn, sprintf("SELECT * FROM closet WHERE category = 'bags' AND id NOT IN (%s) ORDER BY RANDOM() LIMIT 1", paste(used_items, collapse = ",")))
    outfit$linen <- dbGetQuery(conn, "SELECT * FROM closet WHERE category = 'linen' ORDER BY RANDOM() LIMIT 1")
  } else if (temperature >= 15 && temperature <= 25) {
    outfit$top <- dbGetQuery(conn, sprintf("SELECT * FROM closet WHERE category = 'shirts' AND id NOT IN (%s) ORDER BY RANDOM() LIMIT 1", paste(used_items, collapse = ",")))
    outfit$bottom <- dbGetQuery(conn, sprintf("SELECT * FROM closet WHERE (category = 'jeans' OR category = 'pants') AND id NOT IN (%s) ORDER BY RANDOM() LIMIT 1", paste(used_items, collapse = ",")))
    outfit$shoes <- dbGetQuery(conn, sprintf("SELECT * FROM closet WHERE category = 'sneakers' AND id NOT IN (%s) ORDER BY RANDOM() LIMIT 1", paste(used_items, collapse = ",")))
    outfit$blazer <- dbGetQuery(conn, sprintf("SELECT * FROM closet WHERE category = 'blazers' AND id NOT IN (%s) ORDER BY RANDOM() LIMIT 1", paste(used_items, collapse = ",")))
    outfit$bag <- dbGetQuery(conn, sprintf("SELECT * FROM closet WHERE category = 'bags' AND id NOT IN (%s) ORDER BY RANDOM() LIMIT 1", paste(used_items, collapse = ",")))
  } else {
    outfit$top <- dbGetQuery(conn, sprintf("SELECT * FROM closet WHERE category = 'sweaters' AND id NOT IN (%s) ORDER BY RANDOM() LIMIT 1", paste(used_items, collapse = ",")))
    outfit$bottom <- dbGetQuery(conn, sprintf("SELECT * FROM closet WHERE (category = 'jeans' OR category = 'pants') AND id NOT IN (%s) ORDER BY RANDOM() LIMIT 1", paste(used_items, collapse = ",")))
    outfit$shoes <- dbGetQuery(conn, sprintf("SELECT * FROM closet WHERE category = 'boots' AND id NOT IN (%s) ORDER BY RANDOM() LIMIT 1", paste(used_items, collapse = ",")))
    outfit$puffer_coat <- dbGetQuery(conn, sprintf("SELECT * FROM closet WHERE category = 'puffer_coats' AND id NOT IN (%s) ORDER BY RANDOM() LIMIT 1", paste(used_items, collapse = ",")))
    outfit$beanie <- dbGetQuery(conn, sprintf("SELECT * FROM closet WHERE category = 'beanies' AND id NOT IN (%s) ORDER BY RANDOM() LIMIT 1", paste(used_items, collapse = ",")))
    outfit$bag <- dbGetQuery(conn, sprintf("SELECT * FROM closet WHERE category = 'bags' AND id NOT IN (%s) ORDER BY RANDOM() LIMIT 1", paste(used_items, collapse = ",")))
  }
  
  if (any(grepl("Rain", weather_desc))) {
    # Removed the unique condition for the raincoat since we only have one
    outfit$raincoat <- dbGetQuery(conn, "SELECT * FROM closet WHERE category = 'raincoat' ORDER BY RANDOM() LIMIT 1")
  }
  
  if (any(grepl("Sunny", weather_desc))) {
    outfit$sunglasses <- dbGetQuery(conn, sprintf("SELECT * FROM closet WHERE category = 'sunglasses' AND id NOT IN (%s) ORDER BY RANDOM() LIMIT 1", paste(used_items, collapse = ",")))
  }
  
  return(outfit)
}

#* Get the Outfit of the Day
#* @get /ootd
#* @serializer contentType list(type = "image/png")
function() {
  # Loading weather data
  weather_data <- readRDS("weather_data.rds")
  temperature <- weather_data$current$temperature
  weather_desc <- weather_data$current$weather_descriptions
  humidity <- weather_data$current$humidity
  precipitation <- weather_data$current$precip
  wind_speed <- weather_data$current$wind_speed
  
  # Connecting to the database
  conn <- dbConnect(SQLite(), dbname = "closet.db")
  
  # Generating unique outfits
  # We use used_items so we know what items have already been generated for Option 1 so we don't have them in Option 2 as well
  # Note: if we run the bash script and have the clothes twice, we might get the same items since they will have different ID's
  used_items <- c()
  outfit1 <- generate_outfit(conn, temperature, weather_desc, used_items)
  # We consider the items different if they have a different id
  used_items <- c(used_items, sapply(outfit1, function(x) if (!is.null(x)) x$id))
  outfit2 <- generate_outfit(conn, temperature, weather_desc, used_items)
  
  # Disconnecting from the database
  dbDisconnect(conn)
  
  # Function to load images
  load_image <- function(path) {
    # Checking if the path is valid and file exists
    if (!is.null(path) && file.exists(path)) {
      # Reading the image using magick
      img <- magick::image_read(path)
      # Converting to raster for plotting
      as.raster(img) 
    } else {
      # Return NULL if the path is invalid or file does not exist
      NULL
    }
  }
  
  # Preparing image rasters for plotting
  image_rasters1 <- lapply(outfit1, function(item) load_image(item$image_path))
  image_rasters2 <- lapply(outfit2, function(item) load_image(item$image_path))
  
  # Saving the plot as a temporary PNG file
  temp_file <- tempfile(fileext = ".png")
  png(filename = temp_file, width = 1400, height = 1000)
  
  # Creating the plot
  # Setting margins and background color
  par(mar = c(4, 4, 2, 1),bg = "#F1F1F1")
  # Initializing a new plot
  plot.new()
  # Setting the plotting window dimensions
  plot.window(xlim = c(0, 1), ylim = c(0, 1))
  
  # Displaying weather information at the top of the plot
  text(0.5, 0.95, paste("Date:", Sys.Date()), cex = 1.7, font = 2)
  text(0.5, 0.90, paste("Weather:", paste(weather_desc, collapse = ", "),
                        "| Temperature:", temperature, "°C"), cex = 1.6)
  text(0.5, 0.85, paste("Precipitation:", precipitation, "% | Humidity:", humidity, "% | Wind Speed:", wind_speed, "mph"), cex = 1.2)
  
  # Helper function to draw columns
  draw_columns <- function(images, x_start, title, img_size = 0.15, spacing = 0.02) {
    # Adding title for the column (Option 1, Option 2)
    text(x_start + 0.15, 0.78, title, cex = 1.5, font = 2, adj = 0.5)
    
    # Column 1: Top, Bottom, Shoes 
    y_start <- 0.60
    if (!is.null(images$top)) rasterImage(images$top, x_start, y_start, x_start + img_size, y_start + img_size)
    y_start <- y_start - (img_size + spacing)
    if (!is.null(images$bottom)) rasterImage(images$bottom, x_start, y_start, x_start + img_size, y_start + img_size)
    y_start <- y_start - (img_size + spacing)
    if (!is.null(images$shoes)) rasterImage(images$shoes, x_start, y_start, x_start + img_size, y_start + img_size)
    
    # Column 2: Bag, Coat (or Blazer/Linen), Raincoat (if Rainy)
    y_start <- 0.60
    if (!is.null(images$bag)) rasterImage(images$bag, x_start + 0.15, y_start, x_start + 0.15 + img_size, y_start + img_size)
    y_start <- y_start - (img_size + spacing)
    
    # Logic for coat, blazer, or linen based on temperature
    if (temperature > 25 && !is.null(images$linen)) {
      rasterImage(images$linen, x_start + 0.15, y_start, x_start + 0.15 + img_size, y_start + img_size)
    } else if (temperature > 15 && !is.null(images$blazer)) {
      rasterImage(images$blazer, x_start + 0.15, y_start, x_start + 0.15 + img_size, y_start + img_size)
    } else if (!is.null(images$puffer_coat)) {
      rasterImage(images$puffer_coat, x_start + 0.15, y_start, x_start + 0.15 + img_size, y_start + img_size)
    }
    y_start <- y_start - (img_size + spacing)
    
    if (!is.null(images$raincoat)) rasterImage(images$raincoat, x_start + 0.15, y_start, x_start + 0.15 + img_size, y_start + img_size)
    
    # Column 3: Sunglasses (if Sunny), Beanie
    y_start <- 0.60
    if (!is.null(images$sunglasses)) rasterImage(images$sunglasses, x_start + 0.3, y_start, x_start + 0.3 + img_size, y_start + img_size)
    y_start <- y_start - (img_size + spacing)
    if (!is.null(images$beanie)) rasterImage(images$beanie, x_start + 0.3, y_start, x_start + 0.3 + img_size, y_start + img_size)
  }
  
  
  # Drawing columns for outfit option 1
  draw_columns(image_rasters1, 0.05, "Option 1")
  
  # Drawing columns for outfit option 1
  draw_columns(image_rasters2, 0.55, "Option 2")
  
  # Closing the plotting device
  dev.off()
  
  # Returning the plot image as binary
  readBin(temp_file, "raw", n = file.info(temp_file)$size)
}


# Here is another function that draws the ootd image, but using only images not plots
# I found it more intuitive but didn't think that it fits the requirements since it was written plot

# function() {
#   weather_data <- readRDS("weather_data.rds")
#   temperature <- weather_data$current$temperature
#   weather_desc <- weather_data$current$weather_descriptions
# 
#   humidity <- weather_data$current$humidity
#   precipitation <- weather_data$current$precip
#   wind_speed <- weather_data$current$wind_speed
# 
#   conn <- dbConnect(SQLite(), dbname = "closet.db")
# 
#   used_items <- c()
#   outfit1 <- generate_outfit(conn, temperature, weather_desc, used_items)
#   used_items <- c(used_items, sapply(outfit1, function(x) if (!is.null(x)) x$id))
#   outfit2 <- generate_outfit(conn, temperature, weather_desc, used_items)
# 
#   dbDisconnect(conn)
# 
#   load_images <- function(outfit) {
#     images <- list()
#     for (item in names(outfit)) {
#       if (!is.null(outfit[[item]])) {
#         img <- image_read(outfit[[item]]$image_path)
#         # Set a uniform background to #F1F1F1 in case of transparency
#         img <- image_background(img, "#F1F1F1")
#         images[[item]] <- image_scale(img, "x200")
#       }
#     }
#     return(images)
#   }
#   images1 <- load_images(outfit1)
#   images2 <- load_images(outfit2)
# 
#   create_columns <- function(images, temperature, weather_desc) {
#     if (temperature > 25) {
#       col1 <- image_append(c(images$top, images$bottom, images$shoes), stack = TRUE) %>%
#         image_background("#F1F1F1")
#       col2 <- image_append(c(images$bag, images$linen), stack = TRUE) %>%
#         image_background("#F1F1F1")
#       if (!is.null(images$raincoat)) {
#         col2 <- image_append(c(col2, images$raincoat), stack = TRUE) %>%
#           image_background("#F1F1F1")
#       }
#       col3 <- if (!is.null(images$sunglasses)) {
#         image_append(c(images$sunglasses), stack = TRUE) %>%
#           image_background("#F1F1F1")
#       } else {
#         image_blank(width = 200, height = 600, color = "#F1F1F1")
#       }
#     } else if (temperature >= 15 && temperature <= 25) {
#       col1 <- image_append(c(images$top, images$bottom, images$shoes), stack = TRUE) %>%
#         image_background("#F1F1F1")
#       col2 <- image_append(c(images$bag, images$blazer), stack = TRUE) %>%
#         image_background("#F1F1F1")
#       if (!is.null(images$raincoat)) {
#         col2 <- image_append(c(col2, images$raincoat), stack = TRUE) %>%
#           image_background("#F1F1F1")
#       }
#       col3 <- if (!is.null(images$sunglasses)) {
#         image_append(c(images$sunglasses), stack = TRUE) %>%
#           image_background("#F1F1F1")
#       } else {
#         image_blank(width = 200, height = 600, color = "#F1F1F1")
#       }
#     } else {
#       col1 <- image_append(c(images$top, images$bottom, images$shoes), stack = TRUE) %>%
#         image_background("#F1F1F1")
#       col2 <- image_append(c(images$bag, images$puffer_coat), stack = TRUE) %>%
#         image_background("#F1F1F1")
#       if (!is.null(images$raincoat)) {
#         col2 <- image_append(c(col2, images$raincoat), stack = TRUE) %>%
#           image_background("#F1F1F1")
#       }
#       col3 <- image_append(c(images$beanie), stack = TRUE) %>%
#         image_background("#F1F1F1")
#     }
#     return(image_append(c(col1, col2, col3), stack = FALSE) %>%
#              image_background("#F1F1F1"))
#   }
# 
#   outfit_image1 <- create_columns(images1, temperature, weather_desc)
#   outfit_image2 <- create_columns(images2, temperature, weather_desc)
# 
# 
#   # Add consistent background for headers
#   outfit_image1 <- image_append(c(
#     image_blank(width = 400, height = 50, color = "white") %>%
#       image_annotate("Option 1", gravity = "center", size = 20, color = "black", font = "Lato"),
#     outfit_image1
#   ), stack = TRUE) %>%
#     image_background("white")
# 
#   outfit_image2 <- image_append(c(
#     image_blank(width = 400, height = 50, color = "white") %>%
#       image_annotate("Option 2", gravity = "center", size = 20, color = "black", font = "Lato"),
#     outfit_image2
#   ), stack = TRUE) %>%
#     image_background("white")
# 
#   start_offset <- 50  # Adjust this to set where the line should start
# 
#   # Create the line with blank space above it
#   vertical_line <- image_append(c(
#     image_blank(width = 5, height = start_offset, color = "white"),  # Blank space
#     image_blank(width = 5, height = max(image_info(outfit_image1)$height , image_info(outfit_image2)$height ) - start_offset, color = "grey60")  # Vertical line
#   ), stack = TRUE)
# 
#   # Combine outfits with the adjusted line
#   combined_outfits <- image_append(c(
#     outfit_image1,
#     vertical_line,
#     outfit_image2
#   ), stack = FALSE) %>%
#     image_background("white")
# 
# 
#   # Add weather info in the top-left corner with custom formatting
#   weather_temp <- image_blank(width = 400, height = 50, color = "white") %>%
#     image_annotate(
#       sprintf("%d°C | %s", temperature, paste(weather_desc, collapse = ", ")),
#       gravity = "northwest", color = "black", size = 22, font = "Lato",location = "+10+10"
#     )
# 
#   weather_date <- image_blank(width = 400, height = 30, color = "white") %>%
#     image_annotate(
#       sprintf("Date: %s", Sys.Date()),
#       gravity = "northwest", color = "black", size = 22, font = "Lato-Bold", location = "+10+0"
#     )
# 
#   weather_details <- image_blank(width = 400, height = 70, color = "white") %>%
#     image_annotate(
#       sprintf("Precipitation: %s%%\nHumidity: %s%%\nWind: %s mph",
#               precipitation, humidity, wind_speed),
#       gravity = "northwest", color = "grey50", size = 18, font = "Lato", location = "+10+0"
#     )
# 
#   # Combine the temperature, date, and other details
#   weather_info <- image_append(c(weather_temp, weather_date, weather_details), stack = TRUE)
# 
# 
# 
#   final_image <- image_append(c(weather_info, combined_outfits), stack = TRUE) %>%
#     image_background("#F1F1F1")
# 
#   temp_file <- tempfile(fileext = ".png")
#   image_write(final_image, temp_file)
# 
#   readBin(temp_file, "raw", n = file.info(temp_file)$size)
# }



# creating the API endpoint for visualising all the product data

#* Get all product data from the closet database
#* @get /rawdata
function() {
  # Connecting to the database
  conn <- dbConnect(SQLite(), dbname = "closet.db")
  
  # Querying all products
  products <- dbGetQuery(conn, "SELECT * FROM closet")
  
  # Disconnecting from the database
  dbDisconnect(conn)
  
  # Returning all product data directly (Plumber will handle JSON serialization)
  return(products)
}