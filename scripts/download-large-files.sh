#!/bin/bash

# Script to download large binary files from GitHub Releases
# This script downloads files that exceed GitHub's 100MB limit

set -e

REPO="rogertan30/HaloLive"
RELEASE_TAG="${1:-latest}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Downloading large binary files from GitHub Releases..."

# Create target directory if it doesn't exist
TARGET_DIR="$PROJECT_ROOT/Sources/ThirdPath/SudGIP-pro/SudGIP.xcframework/ios-arm64/SudGIP.framework"
mkdir -p "$TARGET_DIR"

# Download the file from GitHub Releases
if [ "$RELEASE_TAG" = "latest" ]; then
    DOWNLOAD_URL=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep "browser_download_url.*SudGIP" | cut -d '"' -f 4)
else
    DOWNLOAD_URL="https://github.com/$REPO/releases/download/$RELEASE_TAG/SudGIP"
fi

if [ -z "$DOWNLOAD_URL" ]; then
    echo "Error: Could not find download URL. Please download manually from:"
    echo "https://github.com/$REPO/releases"
    exit 1
fi

echo "Downloading from: $DOWNLOAD_URL"
curl -L -o "$TARGET_DIR/SudGIP" "$DOWNLOAD_URL"

# Make it executable
chmod +x "$TARGET_DIR/SudGIP"

echo "✓ Successfully downloaded large binary files"
echo "File location: $TARGET_DIR/SudGIP"

