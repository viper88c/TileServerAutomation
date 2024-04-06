#!/bin/bash

# Install necessary dependencies
echo "Installing necessary dependencies..."
sudo apt update
sudo apt install -y unzip jq curl software-properties-common

# Install Node.js and npm
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt install -y nodejs

# Install mapshaper, tippecanoe, and tileserver-gl-light
echo "Installing mapshaper, tippecanoe, and tileserver-gl-light..."
sudo npm install -g mapshaper tippecanoe tileserver-gl-light

# Install PM2
sudo npm install -g pm2

# Clone the Automated TileServer repository
echo "Cloning Automated TileServer repository..."
# Replace the following URL with your repository's URL
git clone https://github.com/viper88c/TileServerAutomation/.git
cd Automated-TileServer

# Make the processzip.sh script executable
chmod +x processzip.sh

# Starting the tile server using pm2
echo "Starting the tile server with pm2..."
pm2 start "tileserver-gl-light -p 3000 zips.mbtiles" --name tileserver

# Save the pm2 process list and configure it to startup on boot
pm2 save
pm2 startup

echo "Automated TileServer setup is complete."
