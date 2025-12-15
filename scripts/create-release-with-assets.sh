#!/bin/bash

# Script to create GitHub Release and upload all large binary files
# Usage: ./scripts/create-release-with-assets.sh [version] [github_token]
# Example: ./scripts/create-release-with-assets.sh 1.0.1 ghp_xxxxxxxxxxxx

set -e

REPO="rogertan30/HaloLive"
VERSION="${1:-1.0.1}"
GITHUB_TOKEN="${2:-$GITHUB_TOKEN}"

# Large files to upload (>10MB)
LARGE_FILES=(
    "Sources/HaloFramework.xcframework/ios-arm64/HaloFramework.framework/Assets.car"
    "Sources/HaloFramework.xcframework/ios-arm64/HaloFramework.framework/HaloFramework"
    "Sources/ThirdPath/SudGIP-pro/SudGIP.xcframework/ios-x86_64-simulator/SudGIP.framework/libiPhone-lib.dylib"
    "Sources/ThirdPath/SudGIP-pro/SudGIP.xcframework/ios-x86_64-simulator/SudGIP.framework/SudGIP"
    "Sources/ThirdPath/SudGIP-pro/SudGIP.xcframework/ios-arm64/SudGIP.framework/SudGIP"
)

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

# Check if tag exists
if git rev-parse "$VERSION" >/dev/null 2>&1; then
    echo "✅ Tag $VERSION exists"
else
    echo "❌ Error: Tag $VERSION does not exist"
    echo "Available tags:"
    git tag -l
    exit 1
fi

echo "🚀 Creating GitHub Release: $VERSION"
echo "📦 Repository: $REPO"
echo "📁 Files to upload: ${#LARGE_FILES[@]}"
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
    \"body\": \"Release $VERSION of HaloFramework Swift Package\\n\\nThis release includes large binary files that are managed via Git LFS.\\n\\n## Large Files Included:\\n$(for file in \"\${LARGE_FILES[@]}\"; do echo \"- \$(basename \"\$file\")\"; done)\\n\\n## Installation\\n\\nUse Swift Package Manager or clone the repository with Git LFS:\\n\\n\`\`\`bash\\ngit clone https://github.com/$REPO.git\\ncd HaloLive\\ngit checkout $VERSION\\ngit lfs install\\ngit lfs pull\\n\`\`\`\",
    \"draft\": false,
    \"prerelease\": false
  }")

# Check if release was created successfully
RELEASE_ID=$(echo "$RELEASE_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

if [ -z "$RELEASE_ID" ]; then
    # Check if release already exists
    EXISTING_RELEASE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
      "https://api.github.com/repos/$REPO/releases/tags/$VERSION")
    
    RELEASE_ID=$(echo "$EXISTING_RELEASE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
    
    if [ -z "$RELEASE_ID" ]; then
        echo "❌ Error: Failed to create release"
        echo "Response: $RELEASE_RESPONSE"
        exit 1
    else
        echo "⚠️  Release already exists (ID: $RELEASE_ID), will upload files to existing release"
    fi
else
    echo "✅ Release created successfully (ID: $RELEASE_ID)"
fi

echo ""

# Step 2: Upload all files
echo "Step 2: Uploading files..."
UPLOADED_COUNT=0
FAILED_FILES=()

for FILE_PATH in "${LARGE_FILES[@]}"; do
    if [ ! -f "$FILE_PATH" ]; then
        echo "⚠️  Warning: File not found: $FILE_PATH (skipping)"
        FAILED_FILES+=("$FILE_PATH")
        continue
    fi
    
    FILE_NAME=$(basename "$FILE_PATH")
    FILE_SIZE=$(stat -f%z "$FILE_PATH" 2>/dev/null || stat -c%s "$FILE_PATH" 2>/dev/null)
    FILE_SIZE_MB=$((FILE_SIZE / 1024 / 1024))
    
    echo "  📤 Uploading: $FILE_NAME (${FILE_SIZE_MB} MB)..."
    
    UPLOAD_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
      -H "Authorization: token $GITHUB_TOKEN" \
      -H "Content-Type: application/octet-stream" \
      --data-binary @"$FILE_PATH" \
      "https://uploads.github.com/repos/$REPO/releases/$RELEASE_ID/assets?name=$FILE_NAME")
    
    HTTP_CODE=$(echo "$UPLOAD_RESPONSE" | tail -1)
    UPLOAD_BODY=$(echo "$UPLOAD_RESPONSE" | sed '$d')
    
    if [ "$HTTP_CODE" = "201" ]; then
        echo "    ✅ Uploaded successfully!"
        ((UPLOADED_COUNT++))
    else
        echo "    ❌ Failed to upload (HTTP $HTTP_CODE)"
        echo "    Response: $UPLOAD_BODY"
        FAILED_FILES+=("$FILE_PATH")
    fi
    echo ""
done

# Summary
echo "=========================================="
echo "📊 Upload Summary"
echo "=========================================="
echo "✅ Successfully uploaded: $UPLOADED_COUNT/${#LARGE_FILES[@]} files"

if [ ${#FAILED_FILES[@]} -gt 0 ]; then
    echo "❌ Failed files:"
    for file in "${FAILED_FILES[@]}"; do
        echo "   - $file"
    done
    exit 1
fi

echo ""
echo "🎉 Release created and all files uploaded!"
echo "📎 Release URL: https://github.com/$REPO/releases/tag/$VERSION"

