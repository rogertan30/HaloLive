# GitHub Release 发布大文件指南

本指南说明如何通过 GitHub Releases 功能发布仓库中的大文件。

## 📋 概述

由于 GitHub 对单个文件有 100MB 的限制，虽然我们使用 Git LFS 管理大文件，但也可以通过 GitHub Releases 提供额外的下载方式。这对于需要直接下载特定版本的用户很有用。

## 🔍 识别大文件

当前仓库中超过 10MB 的大文件：

1. **HaloFramework.xcframework**
   - `Sources/HaloFramework.xcframework/ios-arm64/HaloFramework.framework/Assets.car` (48 MB)
   - `Sources/HaloFramework.xcframework/ios-arm64/HaloFramework.framework/HaloFramework` (82 MB)

2. **SudGIP.xcframework**
   - `Sources/ThirdPath/SudGIP-pro/SudGIP.xcframework/ios-x86_64-simulator/SudGIP.framework/libiPhone-lib.dylib` (74 MB)
   - `Sources/ThirdPath/SudGIP-pro/SudGIP.xcframework/ios-x86_64-simulator/SudGIP.framework/SudGIP` (87 MB)
   - `Sources/ThirdPath/SudGIP-pro/SudGIP.xcframework/ios-arm64/SudGIP.framework/SudGIP` (115 MB)

## 🚀 方法 1: 使用自动化脚本（推荐）

### 前置要求

1. **创建 GitHub Token**
   - 访问：https://github.com/settings/tokens
   - 点击 "Generate new token (classic)"
   - 选择 `repo` 权限
   - 复制生成的 token（格式：`ghp_xxxxxxxxxxxx`）

2. **确保 tag 已存在**
   ```bash
   git tag -l  # 查看所有 tag
   ```

### 执行脚本

```bash
cd /Users/roger/Desktop/HaloLive

# 方式 1: 直接提供 token
./scripts/create-release-with-assets.sh 1.0.1 ghp_你的token

# 方式 2: 使用环境变量
export GITHUB_TOKEN=ghp_你的token
./scripts/create-release-with-assets.sh 1.0.1
```

脚本会自动：
- ✅ 创建 GitHub Release（如果不存在）
- ✅ 上传所有大文件到 Release
- ✅ 显示上传进度和结果

## 🌐 方法 2: 通过 GitHub Web 界面

### 步骤

1. **访问 Releases 页面**
   - 打开：https://github.com/rogertan30/HaloLive/releases
   - 点击 "Create a new release"

2. **填写 Release 信息**
   - **Choose a tag**: 选择或创建 tag（如 `1.0.1`）
   - **Release title**: 输入版本号（如 `1.0.1`）
   - **Description**: 添加发布说明

3. **上传大文件**
   - 在 "Attach binaries by dropping them here" 区域
   - 拖拽或选择以下文件：
     - `Sources/HaloFramework.xcframework/ios-arm64/HaloFramework.framework/Assets.car`
     - `Sources/HaloFramework.xcframework/ios-arm64/HaloFramework.framework/HaloFramework`
     - `Sources/ThirdPath/SudGIP-pro/SudGIP.xcframework/ios-x86_64-simulator/SudGIP.framework/libiPhone-lib.dylib`
     - `Sources/ThirdPath/SudGIP-pro/SudGIP.xcframework/ios-x86_64-simulator/SudGIP.framework/SudGIP`
     - `Sources/ThirdPath/SudGIP-pro/SudGIP.xcframework/ios-arm64/SudGIP.framework/SudGIP`

4. **发布**
   - 点击 "Publish release"

## 💻 方法 3: 使用 GitHub CLI (gh)

### 安装 GitHub CLI

```bash
# macOS
brew install gh

# 登录
gh auth login
```

### 创建 Release 并上传文件

```bash
cd /Users/roger/Desktop/HaloLive

# 创建 release 并上传所有大文件
gh release create 1.0.1 \
  --title "1.0.1" \
  --notes "Release 1.0.1 of HaloFramework Swift Package" \
  Sources/HaloFramework.xcframework/ios-arm64/HaloFramework.framework/Assets.car \
  Sources/HaloFramework.xcframework/ios-arm64/HaloFramework.framework/HaloFramework \
  Sources/ThirdPath/SudGIP-pro/SudGIP.xcframework/ios-x86_64-simulator/SudGIP.framework/libiPhone-lib.dylib \
  Sources/ThirdPath/SudGIP-pro/SudGIP.xcframework/ios-x86_64-simulator/SudGIP.framework/SudGIP \
  Sources/ThirdPath/SudGIP-pro/SudGIP.xcframework/ios-arm64/SudGIP.framework/SudGIP
```

## 🔧 方法 4: 使用 curl 和 GitHub API

### 创建 Release

```bash
GITHUB_TOKEN="your_github_token"
REPO="rogertan30/HaloLive"
VERSION="1.0.1"

# 创建 release
curl -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/$REPO/releases" \
  -d "{
    \"tag_name\": \"$VERSION\",
    \"name\": \"$VERSION\",
    \"body\": \"Release $VERSION of HaloFramework Swift Package\"
  }"
```

### 获取 Release ID

```bash
RELEASE_ID=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$REPO/releases/tags/$VERSION" | \
  grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)

echo "Release ID: $RELEASE_ID"
```

### 上传文件

```bash
# 上传单个文件
curl -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @"Sources/HaloFramework.xcframework/ios-arm64/HaloFramework.framework/HaloFramework" \
  "https://uploads.github.com/repos/$REPO/releases/$RELEASE_ID/assets?name=HaloFramework"

# 重复上述命令上传其他文件
```

## 📦 方法 5: 创建 ZIP 压缩包（适用于多个文件）

如果文件很多，可以创建一个 ZIP 压缩包：

```bash
cd /Users/roger/Desktop/HaloLive

# 创建包含所有大文件的 ZIP
zip -r HaloFramework-large-files.zip \
  Sources/HaloFramework.xcframework/ios-arm64/HaloFramework.framework/Assets.car \
  Sources/HaloFramework.xcframework/ios-arm64/HaloFramework.framework/HaloFramework \
  Sources/ThirdPath/SudGIP-pro/SudGIP.xcframework/

# 然后通过上述任一方法上传 ZIP 文件
```

## ✅ 验证 Release

创建 Release 后，访问以下链接验证：

- Release 页面：https://github.com/rogertan30/HaloLive/releases
- 应该能看到：
  - ✅ Release 信息
  - ✅ 所有上传的大文件
  - ✅ 文件大小正确

## 📝 注意事项

1. **文件大小限制**
   - GitHub Releases 单个文件限制：2GB
   - 建议单个文件不超过 100MB（虽然技术上可以更大）

2. **Git LFS vs Releases**
   - Git LFS：适合版本控制和开发
   - Releases：适合最终用户下载特定版本

3. **更新 Release**
   - 如果 Release 已存在，脚本会自动检测并上传文件到现有 Release
   - 可以通过 Web 界面删除旧文件并重新上传

4. **下载说明**
   - 在 Release 描述中添加下载和使用说明
   - 提醒用户也可以通过 Git LFS 获取文件

## 🔗 相关资源

- [GitHub Releases API 文档](https://docs.github.com/en/rest/releases/releases)
- [Git LFS 文档](https://git-lfs.github.com/)
- [GitHub CLI 文档](https://cli.github.com/manual/)

