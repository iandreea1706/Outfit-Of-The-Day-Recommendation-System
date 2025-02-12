#                      Outfit Recommendation System

###                                                       Andreea Iordache

#### Short Description

The purpose of this project is to create a personalised outfit recommendation system based on the current weather, using products from Mytheresa.

No matter the weather, the outfit will contain a top, bottoms, shoes, bag and outerwear. However, the type of each depends on the current temperature.

On sunny days, sunglasses will be suggested, and on rainy days a raincoat will be provided. During cold weather (under 15 degrees C), a beanie will be provided alongside the other elements.

#### Prerequisites and Dependencies

-   Install R (I used version 4.3.1)
-   Install the necessary libraries: rvest, dplyr, httr, magrittr, jsonlite, magick, plumber, RSQLite

```{r}
install.packages(c("rvest", "dplyr", "httr","magrittr", "jsonlite", "magick", "plumber", "RSQLite"))
```

-   Have Git Bash installed if working on a Windows

#### Installation and Setup Instructions

First, download the archive containing the files and unzip it. Then:

1.  Create a directory on your PC that contains the following files:

-   A directory called ***images***
-   The 5 R scripts: ***product_scraping.R, weatherstack_api.R, etl.R, ootd_api.R, run_ootd_api.R***

2.  Obtaining and setting up the Weatherstack API key

-   Visit the [Weatherstack website.](https://weatherstack.com/)
-   Sign up or log in to your account.
-   Generate a free or paid API key.

3.  Exporting the API Key as an Environment Variable

-   Open your terminal (or Git Bash on Windows).

-   Run the following command to export the API key:

    ```         
    export YOUR_ACCESS_KEY = your_weatherstack_api_key
    ```

\*Replace your_weatherstack_api_key with your actual API key.

3.2. Alternatively:

-   I created a .Renviron file for the acces key of the weatherstack API

    ``` R
    YOUR_ACCESS_KEY = your_api_key_here
    ```

Your environment is now set up and ready to use the Outfit Recommendation System!

#### Project Structure Overview

#### Scripts

-   ***product_scraping.R:***

    -    scrapes product data and images from the web (myTheresa) for the provided category URLs using the rvest library in R. The data includes product names, categories, and associated images. The scraped products are saved as ***products_raw.csv*** for use in the recommendation engine (name, category, image path), and the pictures of the products are saved in the ***images*** directory.

-   ***weatherstack_api.R:***

    -   Fetches current weather data using the Weatherstack API using an API key provided as an environment variable. This data includes temperature, date, precipitation, humidity, and descriptive weather conditions (e.g., sunny, rainy). It is saved in the ***weather_data.rds*** file.

-   ***etl.R:***

    -   Cleans and processes scraped product data, and populates the SQLite database (`closet.db`) with the structured information.

-   ***ootd_api.R:***

    -   Defines the API endpoints using Plumber for generating and serving outfit recommendations.

    -   Two endpoints:

        -   /ootd: generates an outfit of the day plot, containing the weather information and product images from each category

        -   /rawdata: generated a JSON file containing all the products from the database

    -   The outfit is generated based on the following conditions **(Recommendation Logic)**:

    -   Based on the temperature:

        -   **Above 25°C:** Light outfits with T-shirts, shorts or skirts, sandals, bag and a linen shirt

        -   **15°C to 25°C:** Comfortable outfits including shirts, jeans or pants, a blazer, sneakers and a bag

        -   **Below 15°C:** Warm outfits including sweaters, puffer coats, beanies, boots, pants or jeans

    -   Additional adjustments based on the weather description:

        -   **Rainy:** A raincoat is added to the recommendation.

        -   **Sunny:** Sunglasses are included in the recommendation.

-   ***run_ootd_api.R:***

    -   A script to run the Plumber API server, making the `ootd_api.R` functionality accessible.

-   ***run_pipeline.sh:***

    -   A Bash script that automates the entire pipeline, running each step sequentially:

        1.  Scraping product data (`product_scraping.R`).

        2.  Fetching weather data (`weatherstack_api.R`).

        3.  Processing the data (`etl.R`).

        4.  Starting the API (`run_ootd_api.R`).

        5.  Generate the ootd (curl -s "<http://localhost:8000/ootd>" --output ootd_plot.png).

#### Directories

-   ***images/:***

    -   Contains the downloaded product images scraped from the web. This directory is automatically created by the project scripts if it does not exist.

#### Database

-   ***closet.db:***

    -   SQLite database containing structured data about the closet, including product details, categories, and image paths. Used for generating outfit recommendations.

#### Usage Instructions:

-   To run the bash script navigate to your project directory and use the following command in Git Bash (for Windows):

```         
./run_pipeline.sh YOUR_ACCESS_KEY
```

-   If Git Bash cannot find RScript: temporarily set the PATH with the following command:

```         
export PATH=\$PATH:/"the path to your R program file bin "
```

-   To run just one of the scripts in Git Bash:

```         
Rscript YOUR_SCRIPT.R
```

-   To access the ootd API:

    -   Run the run_ootd_api.R script. This will open a new window were you can test the api. If you don't want to use the pop-up window, copy-paste this link into your browser:

    For ootd: [`http://localhost:8000/ootd`](http://localhost:8000/ootd)

    For raw data: [`http://localhost:8000/rawdata`](http://localhost:8000/rawdata)

    -   You can use ***curl***:

        ``` bash
        curl -s "http://localhost:8000/ootd" --output ootd_plot.png
        ```

#### Output Description:

-   products_raw.csv: Contains the scraped product data: name, category, image path

-   weather_data.rds: Stores the current weather data for further use, we will use temperature, date, precipitation, humidity, and descriptive weather conditions (e.g., sunny, rainy)

-   closet.db: The database that contains the products from products_raw.csv: id, name, category, image path

-   ootd_plot.png: Displays the generated outfit recommendations.

    -    On the top it contains the weather data obtained with the help of the weatherstack API: weather temperature and conditions, followed by the date, precipitation, humidity and wind speed

    -   Two outfit options are shown, divided by a line in the middle

    -   Each outfit is composed by three columns

        -   The first column contains the top, bottoms and shoes

        -   The second column contains the bag and outerwear, and a raincoat if it is rainy

        -   The third column contains sunglasses if it is sunny and a beanie if it is under 15 degrees celsuis

####  Additional Features (Bonus Implementations):

-   There are 87 products in the database (5 from each of the 17 categories, one raincoat and one linen shirt for warm weather)

-   The ootd API recommends two outfits, not one

### Troubleshooting and FAQs

This section addresses common issues that might arise while running the project and provides solutions to ensure a smooth experience.

1.  **API Key Errors**

    **Issue:** "API key not found" or "Invalid API key" error while fetching weather data.

    -   Ensure you have obtained a valid API key from [Weatherstack website.](https://weatherstack.com/)

    -   Verify the .Renviron file includes the API key setup:

        ```{r}
        YOUR_ACCESS_KEY = "your_api_key"

        ```

    -   Or Set the API key as an environment variable:

        ```         
        export YOUR_ACCESS_KEY = <your_api_key>
        ```

    -   Restart your terminal or R session to reload environment variables.

2.  **Missing Dependencies**

    **Issue**: Errors like `"package 'name' not found"` when running scripts.

    -   Install the missing package in R:

        ```{r}
        install.packages("name")

        ```

3.  **Port Conflicts**

    **Issue:** The API server does not start, and the terminal shows a "port already in use" error.

    -   In bash: Check which process is using the port (default: `8000`):

        ```         
        lsof -i :8000
        ```

    -   Kill the conflicting process:

        ```         
        bash
        kill -9 <process_id>
        ```

    -   Or, run the API server on a different port by modifying the `run_ootd_api.R` script:

        ```         
        R
        pr$run(port = 8080)
        ```

4.   **SSL or Connection Errors While Scraping**

    **Issue:** "SSL verification failed" or "Forbidden (HTTP 403)" errors during web scraping.

    -   Disable SSL verification in your script:

        ```         
        R
        httr::set_config(httr::config(ssl_verifypeer = FALSE))
        ```

    -   Use a user-agent string to avoid being blocked:

        ```         
        R
        read_html(url, user_agent("Mozilla/5.0"))
        ```

5.   **Tips for Ensuring Smooth Execution**

-   Internet Connection:

    -   Ensure your system is connected to the internet while fetching data from APIs or web scraping.

-   Environment Setup:

    -   Run all scripts in the correct order to avoid missing dependencies or data:

        -   product_scraping.R

        -   weatherstack_api.R

        -   etl.R

        -   run_ootd_api.R

6.  **Important Note**

    Even though I have created a function to ensure that the two outfit options generated are unique, if run in bash, the API can include some of the same products. This is because before running in Bash, the database will already contain the products. Bash will run the *etl.R* and include in the database the products again. Even though for us the products will be the same (duplicated), they will have different ID's, and since the function considers two products the same if they have the same ID, they will not be excluded for Option 2.
