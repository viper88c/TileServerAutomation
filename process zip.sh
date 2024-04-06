#!/bin/bash

# Ensure the script is executed with an argument
if [ "$#" -ne 1 ]; then
    echo "Usage: ./processzip.sh <input_directory_containing_zip>"
    exit 1
fi

INPUT_DIR=$1

# Check if the input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    echo "The directory $INPUT_DIR does not exist."
    exit 1
fi

# Find the ZIP file in the directory and unzip it
ZIP_FILE=$(find "$INPUT_DIR" -name '*.zip' | head -n 1)

if [ -z "$ZIP_FILE" ]; then
    echo "No ZIP file found in $INPUT_DIR."
    exit 1
fi

echo "Unzipping $ZIP_FILE..."
unzip -o "$ZIP_FILE" -d "$INPUT_DIR"

# Identify the .dbf file
DBF_FILE=$(find "$INPUT_DIR" -name '*.dbf' | head -n 1)

if [ -z "$DBF_FILE" ]; then
    echo "No DBF file found in $INPUT_DIR."
    exit 1
fi

# Determine the layer type by inspecting the DBF file
if grep -qi "ZCTA" "$DBF_FILE"; then
    LAYER_NAME="ZipCodes"
elif grep -qi "COUNTYFP" "$DBF_FILE"; then
    LAYER_NAME="Counties"
elif grep -qi "CITYFP" "$DBF_FILE"; then
    LAYER_NAME="Cities"
elif grep -qi "STATEFP" "$DBF_FILE"; then
    LAYER_NAME="States"
else
    echo "Unrecognized shapefile type."
    exit 1
fi

echo "Detected layer type: $LAYER_NAME"

# Proceed with the existing steps to process the shapefiles
mapshaper -i "$INPUT_DIR"/*.shp combine-files snap -simplify visvalingam keep-shapes percentage=4% -o format=geojson out.geojson

# Filter out features with null geometries
jq 'del(.features[] | select(.geometry == null))' out.geojson > temp.geojson && mv temp.geojson out.geojson

# Calculate the bounding box for each feature and add center coordinates as properties
mapshaper out.geojson -each 'this.properties.CENTER_X = (this.bounds[0] + this.bounds[2]) / 2; this.properties.CENTER_Y = (this.bounds[1] + this.bounds[3]) / 2' -o temp.geojson
mv temp.geojson out.geojson

# Filter out unnecessary properties from the GeoJSON file and set 'id' to a numeric 'GEOID20'
jq '.features |= map({type: .type, id: (.properties.GEOID20 | tonumber), geometry: .geometry, properties: {GEOID20: .properties.GEOID20, CENTER_X: .properties.CENTER_X, CENTER_Y: .properties.CENTER_Y}})' out.geojson > temp.geojson && mv temp.geojson out.geojson

# Check if zips.mbtiles exists and remove it if it does
if [ -f zips.mbtiles ]; then
    echo "zips.mbtiles exists. Removing..."
    rm zips.mbtiles
fi

# Convert the GeoJSON to an MBTiles file with tippecanoe
tippecanoe -o zips.mbtiles -Z 0 -z 12 -l $LAYER_NAME out.geojson -f

# Remove the intermediate GeoJSON file and all files in the input directory
rm out.geojson
rm -r "$INPUT_DIR"/*

echo "Process complete. All temporary files removed, exported to zips.mbtiles."
