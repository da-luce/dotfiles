#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# List of "icon_file app_name" pairs
APPS=(
  "alacritty.icns Alacritty.app"
  "Icon.icns Spotify.app" # not working :(
)

for pair in "${APPS[@]}"; do
  ICON_FILE=$(echo "$pair" | cut -d' ' -f1)
  APP_NAME=$(echo "$pair" | cut -d' ' -f2)

  ICON_PATH="$SCRIPT_DIR/$ICON_FILE"
  APP_PATH="/Applications/$APP_NAME"
  DEST_ICON_PATH="$APP_PATH/Contents/Resources/$ICON_FILE"
  PLIST_PATH="$APP_PATH/Contents/Info.plist"

  echo "📦 Processing $APP_NAME..."

  if [ ! -f "$ICON_PATH" ]; then
    echo "  ⚠️  Icon file not found: $ICON_PATH. Skipping."
    continue
  fi

  if [ ! -d "$APP_PATH" ]; then
    echo "  ⚠️  App not found: $APP_PATH. Skipping."
    continue
  fi

  echo "    Copying $ICON_FILE to $DEST_ICON_PATH"
  cp "$ICON_PATH" "$DEST_ICON_PATH"

  echo "    Updating Info.plist..."
  plutil -replace CFBundleIconFile -string "$ICON_FILE" "$PLIST_PATH"

  echo "    Touching app bundle..."
  touch "$APP_PATH"

  echo "    Finished $APP_NAME"
done

# Restart Dock to apply changes
echo "Restarting Dock to refresh icons..."
killall Dock

echo "🎉 All done!"
