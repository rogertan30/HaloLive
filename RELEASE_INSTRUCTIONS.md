# GitHub Release 设置说明

## 步骤 1: 推送代码到 GitHub

执行以下命令推送代码：

```bash
cd /Users/roger/Desktop/HaloLive

# 先推送 LFS 对象（如果有其他大文件）
git lfs push origin main --all

# 推送代码
git push -u origin main --force
```

## 步骤 2: 创建 GitHub Release 并上传大文件

### 方法 1: 通过 GitHub Web 界面

1. 访问你的仓库：https://github.com/rogertan30/HaloLive
2. 点击右侧的 "Releases" 链接
3. 点击 "Create a new release"
4. 填写信息：
   - **Tag version**: `v1.0.0` (或你想要的版本号)
   - **Release title**: `v1.0.0` (或描述性标题)
   - **Description**: 可以添加发布说明
5. 在 "Attach binaries" 部分，上传大文件：
   - 文件路径：`Sources/ThirdPath/SudGIP-pro/SudGIP.xcframework/ios-arm64/SudGIP.framework/SudGIP`
   - 或者创建一个 zip 文件包含该文件
6. 点击 "Publish release"

### 方法 2: 使用 GitHub CLI (gh)

如果你安装了 GitHub CLI，可以使用命令行：

```bash
# 创建 release 并上传文件
gh release create v1.0.0 \
  --title "v1.0.0" \
  --notes "Initial release of HaloFramework" \
  Sources/ThirdPath/SudGIP-pro/SudGIP.xcframework/ios-arm64/SudGIP.framework/SudGIP
```

### 方法 3: 使用 curl 和 GitHub API

```bash
# 1. 创建 release (需要 GitHub token)
GITHUB_TOKEN="your_github_token"
REPO="rogertan30/HaloLive"
TAG="v1.0.0"

# 创建 release
curl -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/$REPO/releases \
  -d "{
    \"tag_name\": \"$TAG\",
    \"name\": \"$TAG\",
    \"body\": \"Initial release of HaloFramework\"
  }"

# 2. 上传文件到 release
RELEASE_ID=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  https://api.github.com/repos/$REPO/releases/tags/$TAG | jq -r '.id')

curl -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @"Sources/ThirdPath/SudGIP-pro/SudGIP.xcframework/ios-arm64/SudGIP.framework/SudGIP" \
  "https://uploads.github.com/repos/$REPO/releases/$RELEASE_ID/assets?name=SudGIP"
```

## 步骤 3: 更新下载脚本（可选）

如果文件名或路径有变化，记得更新 `scripts/download-large-files.sh` 中的下载 URL 匹配规则。

## 注意事项

- 确保上传的文件名与脚本中期望的文件名一致
- 如果使用 zip 文件，需要更新下载脚本以解压文件
- 建议在 README.md 中提供清晰的下载说明

