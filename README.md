# Automated TileServer

This tool automates the process of generating MBTiles from shapefiles, specifically designed for handling ZIP codes, counties, cities, and states data.

## Setup

To set up the Automated TileServer, follow these steps:

1. **Clone the repository:**
   
   ```bash
   git clone https://github.com/yourrepository/AutomatedTileServer.git
   cd AutomatedTileServer
   ```

2. **Run the setup script:**

   This script installs necessary dependencies like `jq`, `mapshaper`, and `tippecanoe`.

   ```bash
   chmod +x setup.sh
   ./setup.sh
   ```

## Usage

1. **Prepare your data:**

   Place your `.zip` files containing the shapefiles in a designated input directory.

2. **Execute the processing script:**

   Run the processing script with the input directory as an argument.

   ```bash
   ./processzip.sh <input_directory_containing_zip>
   ```

   This script will identify the type of shapefile (ZIP codes, counties, cities, or states), process them, and integrate them into an MBTiles file.

## Features

- Automatically detects the type of geographical data in the shapefile.
- Simplifies and optimizes the shapefiles for tile generation.
- Updates an existing MBTiles file with new data or creates a new one if it doesn't exist.

## Requirements

- jq
- mapshaper
- tippecanoe

Ensure these dependencies are installed and accessible in your PATH.
