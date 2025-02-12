#!/bin/bash

# Usage: ./run_pipeline.sh YOUR_ACCESS_KEY
# Check if the API key is provided
if [ -z "$1" ]; then
    echo "Usage: $0 YOUR_ACCESS_KEY"
    exit 1
fi
# Get the API key from the command-line argument
 YOUR_API_KEY=$1
# Export the API key as an environment variable
export YOUR_ACCESS_KEY=$1

# Step 1: Scrape product data
echo "Step 1: Scraping product data..."
Rscript product_scraping.R
if [ $? -ne 0 ]; then
    echo "Error in product_scraping.R"
    exit 1
fi

# Step 2: Fetch weather data
echo "Step 2: Fetching weather data..."
Rscript weatherstack_api.R
if [ $? -ne 0 ]; then
    echo "Error in weatherstack_api.R"
    exit 1
fi

# Step 3: ETL Process
echo "Step 3: Running ETL process..."
Rscript etl.R
if [ $? -ne 0 ]; then
    echo "Error in etl.R"
    exit 1
fi

# Step 4: Start Plumber API
echo "Step 4: Starting the API server..."
Rscript run_ootd_api.R &
API_PID=$!

# Wait for the API to start
sleep 5

# Step 5: Call /ootd endpoint to generate outfit plot
echo "Step 5: Generating outfit plot..."
curl -s "http://localhost:8000/ootd" --output ootd_plot.png
if [ $? -ne 0 ]; then
    echo "Error: Failed to generate outfit plot."
    kill $API_PID
    exit 1
fi

echo "Outfit plot saved as ootd_plot.png."

# Stop the API server
kill $API_PID
echo "Pipeline completed successfully."
