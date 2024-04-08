
# Automated TileServer

This project provides a comprehensive solution for setting up and managing a TileServer with automated processes for handling shapefile conversions and tile serving using tileserver-gl-light and PM2.

## Installation

Clone the repository to your local machine:

```bash
git clone https://github.com/viper88c/TileServerAutomation.git
cd TileServerAutomation
```

Run the setup script to install all necessary dependencies:

```bash
./setup.sh
```

## Usage

After installation, you can use the script to process shapefiles into MBTiles format:

```bash
./processtiles.sh <input_directory_containing_tile>
```

This script will detect the type of geographic data (e.g., Zip Codes, Counties, Cities, States), process the shapefiles, and update the corresponding layers in `tiles.mbtiles`.

### TileServer and PM2

The project uses tileserver-gl-light to serve tiles and PM2 for process management. To start the TileServer on port 3000:

```bash
pm2 start "tileserver-gl-light -p 3000 tiles.mbtiles" --name tileserver
```

To check the status of the TileServer:

```bash
pm2 status tileserver
```

To stop the TileServer:

```bash
pm2 stop tileserver
```

## Additional Notes

Ensure your shapefiles are placed in the specified input directory before running the processing script. The script will unzip, process, and integrate the shapefile data into the TileServer automatically.

For more information on PM2 and tileserver-gl-light, refer to their respective documentation.

