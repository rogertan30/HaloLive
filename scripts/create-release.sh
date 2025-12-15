#!/bin/bash

# Script to create GitHub Release and upload large binary file
# Usage: ./scripts/create-release.sh [version] [github_token]
# Example: ./scripts/create-release.sh v1.0.0 ghp_xxxxxxxxxxxx

set -e

REPO="rogertan30/HaloLive"
VERSION="${1:-v1.0.0}"
GITHUB_TOKEN="${2:-$GITHUB_TOKEN}"
FILE_PATH="Sources/ThirdPath/SudGIP-pro/SudGIP.xcframework/ios-arm64/SudGIP.framework/SudGIP"

if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ Error: GitHub token is required"
    echo ""
    echo "Usage:"
    echo "  $0 [version] [github_token]"
    echo ""
    echo "Or set GITHUB_TOKEN environment variable:"
    echo "  export GITHUB_TOKEN=ghp_xxxxxxxxxxxx"
    echo "  $0 $VERSION"
    echo ""
    echo "To create a GitHub token:"
    echo "  1. Go to https://github.com/settings/tokens"
    echo "  2. Click 'Generate new token (classic)'"
    echo "  3. Select 'repo' scope"
    echo "  4. Copy the token and use it here"
    exit 1
fi

if [ ! -f "$FILE_PATH" ]; then
    echo "❌ Error: File not found: $FILE_PATH"
    exit 1
fi

echo "🚀 Creating GitHub Release: $VERSION"
echo "📦 Repository: $REPO"
echo "📁 File: $FILE_PATH"
echo ""

# Step 1: Create the release
echo "Step 1: Creating release..."
RELEASE_RESPONSE=$(curl -s -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/$REPO/releases" \
  -d "{
    \"tag_name\": \"$VERSION\",
    \"name\": \"$VERSION\",
    \"body\": \"Initial release of HaloFramework Swift Package\\n\\nThis release includes the large binary file that exceeds GitHub's 100MB limit.\",
    \"draft\": false,
    \"prerelease\": false
  }")

# Check if release was created successfully
RELEASE_ID=$(echo "$RELEASE_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

if [ -z "$RELEASE_ID" ]; then
    echo "❌ Error: Failed to create release"
    echo "Response: $RELEASE_RESPONSE"
    exit 1
fi

echo "✅ Release created successfully (ID: $RELEASE_ID)"
echo ""

# Step 2: Upload the file
echo "Step 2: Uploading file..."
FILE_NAME=$(basename "$FILE_PATH")
FILE_SIZE=$(stat -f%z "$FILE_PATH")
FILE_SIZE_MB=$((FILE_SIZE / 1024 / 1024))

echo "  File: $FILE_NAME"
echo "  Size: ${FILE_SIZE_MB} MB"
echo "  Uploading..."

UPLOAD_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @"$FILE_PATH" \
  "https://uploads.github.com/repos/$REPO/releases/$RELEASE_ID/assets?name=$FILE_NAME")

HTTP_CODE=$(echo "$UPLOAD_RESPONSE" | tail -1)
UPLOAD_BODY=$(echo "$UPLOAD_RESPONSE" | sed '$d')

if [ "$HTTP_CODE" = "201" ]; then
    echo "✅ File uploaded successfully!"
    echo ""
    echo "🎉 Release created and file uploaded!"
    echo "📎 Release URL: https://github.com/$REPO/releases/tag/$VERSION"
else
    echo "❌ Error: Failed to upload file (HTTP $HTTP_CODE)"
    echo "Response: $UPLOAD_BODY"
    exit 1
fi

