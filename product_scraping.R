# Loading the libraries
# for web scraping
library(rvest)
# for data manipulation
library(dplyr)

# Creating directory for images if it doesn't already exist
if (!dir.exists("images")) {
  dir.create("images")
}

# Defining the list of categories and their URLs fromn myTheresa
categories <- list(
  dresses = "https://www.mytheresa.com/gb/en/women/clothing/dresses",
  t_shirts = "https://www.mytheresa.com/gb/en/women/clothing/tops/t-shirts",
  sweaters = "https://www.mytheresa.com/gb/en/women/clothing/knitwear/sweaters",
  jeans = "https://www.mytheresa.com/gb/en/women/clothing/jeans",
  skirts = "https://www.mytheresa.com/gb/en/women/clothing/skirts",
  shorts = "https://www.mytheresa.com/gb/en/women/clothing/shorts",
  pants = "https://www.mytheresa.com/gb/en/women/clothing/pants",
  wool_coat = "https://www.mytheresa.com/gb/en/women/clothing/coats/wool-coats",
  puffer_coats = "https://www.mytheresa.com/gb/en/women/clothing/coats/puffer-down-coats",
  sunglasses = "https://www.mytheresa.com/gb/en/women/accessories/sunglasses",
  beanies = "https://www.mytheresa.com/gb/en/women/accessories/hats?categories=3927",
  sneakers = "https://www.mytheresa.com/gb/en/women/shoes/sneakers",
  boots = "https://www.mytheresa.com/gb/en/women/shoes/ankle-boots",
  sandals = "https://www.mytheresa.com/gb/en/women/shoes/espadrilles",
  shirts = "https://www.mytheresa.com/gb/en/women/clothing/tops/shirts",
  raincoat = "https://www.mytheresa.com/gb/en/women/moncler-grenoble-landry-raincoat-blue-p00642939",
  bags = "https://www.mytheresa.com/gb/en/women/bags/shoulder-bags",
  blazers = "https://www.mytheresa.com/gb/en/women/clothing/jackets/blazers",
  linen = "https://www.mytheresa.com/gb/en/women/alemais-embroidered-linen-shirt-white-p00946818"
)

# Initializing an empty data frame to store product data (name, categorym image path)
products <- data.frame(
  name = character(),
  category = character(),
  image_path = character(),
  # Disabling automatic conversion to factors
  stringsAsFactors = FALSE
)

# Function to clean product names for file paths
clean_name <- function(name) {
  gsub("[^a-zA-Z0-9]", "_", name)
}
# Function to mimic real user behavior so we don't get blocked when we scrape the data; don't use it anymore
mimic_user <- function() {
  Sys.sleep(runif(1, 2, 5)) # Random delay between 2-5 seconds
}


# Scraping data for each category
for (cat in names(categories)) {
  # Retrieving the URL for the current category
  url <- categories[[cat]]
  
 # mimic_user() # Mimic user delay
  # webpage <- tryCatch(
  #   read_html(httr::GET(url, user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36"))),
  #   error = function(e) NULL
  # )
  
  # Reading the webpage
  webpage <- tryCatch(read_html(url), error = function(e) NULL)

  # If the webpage fails to load, it skips to the next category
   if (is.null(webpage)) {
    message(paste("Failed to load category:", cat))
    next
  }
  
  # Check if the URL is a single product; we need this for the raincoat and the linen
  # Since the url links to a specific product, not a category 
  if (grepl("/women/.+-raincoat-", url) || grepl("/women/.+-linen-", url)) {
    # Extracting product title
    product_title <- webpage %>%
      html_node(".product__area__branding__name") %>%
      html_text(trim = TRUE)
    
    # Extracting product image URL
    image_url <- webpage %>%
      html_node(".product__gallery__carousel__image") %>%
      html_attr("src")
    
    # Downloading the image
    image_path <- paste0("images/", clean_name(product_title), ".jpg")
    tryCatch({
      download.file(image_url, destfile = image_path, mode = "wb")
    }, error = function(e) {
      message(paste("Failed to download image:", image_url))
      next
    })
    
    # Add to products data frame
    products <- rbind(
      products,
      data.frame(
        name = product_title,
        category = cat,
        image_path = image_path,
        stringsAsFactors = FALSE
      )
    )
    next
  }
  
  # For category pages, extract product links
  product_links <- webpage %>%
    html_nodes(".item__link") %>%
    html_attr("href")
  
  # Ensuring links are absolute URLs
  product_links <- paste0("https://www.mytheresa.com", product_links)
  
  # Extracting product titles
  product_titles <- webpage %>%
    html_nodes(".item__link img") %>%
    html_attr("alt")
  
  # Extracting image URLs
  image_urls <- webpage %>%
    html_nodes(".item__images__image img") %>%
    html_attr("src")
  
  # I only want the first 5 items
  product_links <- head(product_links, 5)
  product_titles <- head(product_titles, 5)
  image_urls <- head(image_urls, 5)
  
  # Downloading images and adding data to products data frame
  for (i in seq_along(product_titles)) {
    
    # Defining the path to save the downloaded image
    image_path <- paste0("images/", clean_name(product_titles[i]), ".jpg")
    tryCatch({
      download.file(image_urls[i], destfile = image_path, mode = "wb")
    }, error = function(e) {
      message(paste("Failed to download image:", image_urls[i]))
      next
    })
    
    # Appending to products data frame
    products <- rbind(
      products,
      data.frame(
        name = product_titles[i],
        category = cat,
        image_path = image_path,
        stringsAsFactors = FALSE
      )
    )
  }
}

# Save data frame for ETL process to csv
if (nrow(products) > 0) {
  write.csv(products, "products_raw.csv", row.names = FALSE)
  print(products)
} else {
  message("No products were scraped.")
}
