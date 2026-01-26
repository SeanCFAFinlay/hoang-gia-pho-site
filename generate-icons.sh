#!/usr/bin/env bash

# Generate iOS & Android app icons from a source image and create a ZIP for site downloads.
# Usage: ./generate-icons.sh path/to/logo-source.png
# Requires: ImageMagick (convert, identify), zip

set -euo pipefail

SRC="$1"
if [ -z "$SRC" ] || [ ! -f "$SRC" ]; then
  echo "Usage: $0 path/to/logo-source.png"
  exit 1
fi

OUTDIR="assets/downloads/app-icons-output"
ZIPDIR="assets/downloads"
ZIPNAME="hoang-gia-pho-app-icons.zip"
TMP="$OUTDIR/tmp"

# Customize these if you want different background or padding
BACKGROUND="#2b2726"    # dark brand background; change to "#f7efe3" for cream
PADDING=64              # padding around the logo inside final canvas
ROUNDED_RADIUS=160      # radius for rounded corners mask (pixels)

# Create directories
rm -rf "$OUTDIR"
mkdir -p "$TMP" "$ZIPDIR"

echo "Source: $SRC"
echo "Output dir: $OUTDIR"
echo "Background: $BACKGROUND"

# 1) Crop a square around the bottom-middle region (adjust logic if needed)
W=$(identify -format "%w" "$SRC")
CROP_SIZE=$W
convert "$SRC" -gravity South -crop "${CROP_SIZE}x${CROP_SIZE}+0+0" +repage "$TMP/cropped.png"

# 2) Remove the light/cream background roughly (tune -fuzz if necessary)
# If your source has a clean cream background this works; otherwise manually provide a transparent PNG.
convert "$TMP/cropped.png" -fuzz 12% -transparent "#f7efe3" "$TMP/logo-trans.png"

# 3) Create a 1024x1024 canvas with the logo centered and padding
target=1024
convert "$TMP/logo-trans.png" -resize "$((target - PADDING*2))x$((target - PADDING*2))" \
  -background none -gravity center -extent ${target}x${target} "$TMP/logo-1024.png"

# Place on background color (so icons are not transparent)
convert -size ${target}x${target} "canvas:${BACKGROUND}" "$TMP/logo-1024.png" -gravity center -composite "$TMP/icon-on-bg-1024.png"

# 3b) Apply rounded-corner mask to create baked rounded corners
# Create a rounded rectangle alpha mask and apply it to the final icon
convert -size ${target}x${target} xc:none -fill white -draw "roundrectangle 0,0 $((target-1)),$((target-1)) ${ROUNDED_RADIUS},${ROUNDED_RADIUS}" "$TMP/mask.png"
# Ensure mask is single-channel alpha
convert "$TMP/mask.png" -alpha off -background black -flatten "$TMP/mask_alpha.png"
# Apply mask to icon (DstIn to keep alpha according to mask)
convert "$TMP/icon-on-bg-1024.png" "$TMP/mask_alpha.png" -alpha set -compose DstIn -composite "$TMP/icon-rounded-1024.png"

# 4) Export iOS icon sizes (common required sizes)
declare -A IOS=(
  ["AppIcon20x20@2x"]="40" ["AppIcon20x20@3x"]="60"
  ["AppIcon29x29@2x"]="58" ["AppIcon29x29@3x"]="87"
  ["AppIcon40x40@2x"]="80" ["AppIcon40x40@3x"]="120"
  ["AppIcon60x60@2x"]="120" ["AppIcon60x60@3x"]="180"
  ["AppIcon76x76"]="76" ["AppIcon76x76@2x"]="152"
  ["AppIcon83.5x83.5@2x"]="167"
  ["AppStore1024"]="1024"
)

mkdir -p "$OUTDIR/ios"
for name in "${!IOS[@]}"; do
  size=${IOS[$name]}
  outfile="$OUTDIR/ios/${name}.png"
  convert "$TMP/icon-rounded-1024.png" -resize "${size}x${size}" "$outfile"
done

# 5) Android icons: Play store + launcher densities
mkdir -p "$OUTDIR/android"
convert "$TMP/icon-rounded-1024.png" -resize 512x512 "$OUTDIR/android/playstore-512.png"

declare -A ANDROID=(
  ["ldpi"]="36" ["mdpi"]="48" ["hdpi"]="72" ["xhdpi"]="96" ["xxhdpi"]="144" ["xxxhdpi"]="192"
)
for qual in "${!ANDROID[@]}"; do
  size=${ANDROID[$qual]}
  convert "$TMP/icon-rounded-1024.png" -resize ${size}x${size} "$OUTDIR/android/ic_launcher_${qual}.png"
done

# 6) Adaptive icon foreground (transparent logo) - recommended 1024x1024
# We also produce a rounded foregroundless (transparent) version for adaptive icons without background baked-in
convert "$TMP/logo-trans.png" -resize 1024x1024 "$OUTDIR/android/ic_foreground_transparent_1024.png"

# 7) Create a small preview image (512)
convert "$TMP/icon-rounded-1024.png" -resize 512x512 "$OUTDIR/preview-512.png"

# 8) Package into a ZIP for direct download
rm -f "$ZIPDIR/$ZIPNAME"
mkdir -p "$ZIPDIR/temp_zip"
cp -r "$OUTDIR"/* "$ZIPDIR/temp_zip/"
cd "$ZIPDIR"
zip -r "$ZIPNAME" temp_zip/*
mv "$ZIPNAME" .
rm -rf temp_zip
cd - >/dev/null

# Cleanup temp if desired (comment out to keep for debugging)
rm -rf "$TMP"

echo "Icons generated in: $OUTDIR. ZIP created at: $ZIPDIR/$ZIPNAME"

# Make sure the script is executable
chmod +x "$0"