#!/bin/bash

# Script to generate iOS and Android icons from a source image
# Produces a ZIP at assets/downloads/hoang-gia-pho-app-icons.zip and a preview image.
# Requires ImageMagick and zip installed.

SOURCE_IMAGE="assets/source/logo-source.png"
DESTINATION_ZIP="assets/downloads/hoang-gia-pho-app-icons.zip"
PREVIEW_IMAGE="assets/downloads/preview.png"

# Set default background and corner rounding
BACKGROUND="#2b2726"
ROUNDED="0"

if [ -f "$SOURCE_IMAGE" ]; then
    # Generate icons
    convert "$SOURCE_IMAGE" -background "$BACKGROUND" -resize 1024x1024 -define icon:auto-resize=64,240,48,72,114,144,152,180,192,512 "$DESTINATION_ZIP"
    # Create a preview image
    convert "$SOURCE_IMAGE" -resize 256x256 "$PREVIEW_IMAGE"
    echo "Icon generation completed successfully!"
else
    echo "Source image not found: $SOURCE_IMAGE"
fi

# Make sure the script is executable
chmod +x generate-icons.sh
