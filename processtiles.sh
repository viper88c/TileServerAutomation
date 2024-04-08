#!/bin/bash

# Check for the correct number of arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: ./processtile.sh <input_directory_containing_zip>"
    exit 1
fi

INPUT_DIR=$1

# Check if the input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    echo "The directory $INPUT_DIR does not exist."
    exit 1
fi

# Find and unzip the ZIP file
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

# Determine the layer type
LAYER_NAME=""
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

# Process the shapefiles into GeoJSON
echo "Processing shapefiles into GeoJSON..."
mapshaper -i "$INPUT_DIR"/*.shp combine-files snap -simplify visvalingam keep-shapes percentage=4% -o format=geojson out.geojson

# Conditional processing based on layer type
if [ "$LAYER_NAME" = "ZipCodes" ]; then
    # Specific processing for ZipCodes
    echo "Processing ZipCodes layer..."
    jq 'del(.features[] | select(.geometry == null))' out.geojson > temp.geojson && mv temp.geojson out.geojson
    mapshaper out.geojson -each 'this.properties.CENTER_X = (this.bounds[0] + this.bounds[2]) / 2; this.properties.CENTER_Y = (this.bounds[1] + this.bounds[3]) / 2' -o temp.geojson
    mv temp.geojson out.geojson
    jq '.features |= map({type: .type, id: (.properties.GEOID20 | tonumber), geometry: .geometry, properties: {GEOID20: .properties.GEOID20, CENTER_X: .properties.CENTER_X, CENTER_Y: .properties.CENTER_Y}})' out.geojson > temp.geojson && mv temp.geojson out.geojson
else
    # Processing for Counties, Cities, and States (keeping all properties for now)
    echo "Processing $LAYER_NAME with all properties retained."
fi

# Create MBTiles for the new layer
echo "Creating MBTiles for the new layer..."
tippecanoe -o new_layer.mbtiles -Z 0 -z 12 -l $LAYER_NAME out.geojson -f

# Check if new_layer.mbtiles was created and is not empty
if [ ! -s new_layer.mbtiles ]; then
    echo "Failed to create new_layer.mbtiles or the file is empty."
    exit 1
else
    echo "new_layer.mbtiles created successfully."
fi

# Update the existing MBTiles file
if [ -f tiles.mbtiles ]; then
    echo "Updating tiles.mbtiles with the new layer..."
    tile-join -o updated_tiles.mbtiles new_layer.mbtiles tiles.mbtiles
    if [ -f updated_tiles.mbtiles ]; then
        echo "Replacing tiles.mbtiles with updated_tiles.mbtiles..."
        mv updated_tiles.mbtiles tiles.mbtiles
    else
        echo "Tile-join did not generate updated_tiles.mbtiles as expected."
        exit 1
    fi
else
    echo "tiles.mbtiles does not exist, renaming new_layer.mbtiles to tiles.mbtiles..."
    mv new_layer.mbtiles tiles.mbtiles
fi

# Clean up
echo "Cleaning up temporary files..."
rm -f new_layer.mbtiles
rm out.geojson
rm -r "$INPUT_DIR"/*
echo "Process complete. All temporary files removed, exported to tiles.mbtiles."
