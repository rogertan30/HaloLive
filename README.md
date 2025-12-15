# HaloFramework

A Swift Package for iOS development.

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/rogertan30/HaloLive.git", from: "1.0.0")
]
```

Or add it through Xcode:
1. File → Add Packages...
2. Enter the repository URL: `https://github.com/rogertan30/HaloLive.git`
3. Select the version you want to use

## Large Binary Files (Git LFS)

This repository uses [Git LFS](https://git-lfs.github.com/) to manage large binary files (including `.mp3` files, `.xcframework` files, and other binaries).

### ⚠️ Important: Downloading with Git LFS

**Do NOT use GitHub's "Download ZIP" button** - it will only download LFS pointer files (~131 bytes) instead of the actual binary files.

### ✅ Correct Download Methods

#### Method 1: Git Clone (Recommended)

```bash
# Clone the repository (Git LFS files will be automatically downloaded)
git clone https://github.com/rogertan30/HaloLive.git
cd HaloLive

# Checkout a specific tag
git checkout 1.0.1

# Ensure Git LFS is installed and pull LFS files
git lfs install
git lfs pull
```

#### Method 2: Using Swift Package Manager

When adding this package via Swift Package Manager in Xcode, Git LFS files are automatically handled. Make sure you have Git LFS installed:

```bash
# Install Git LFS (if not already installed)
brew install git-lfs
git lfs install
```

#### Method 3: Manual Git LFS Setup

If you've already cloned without LFS files:

```bash
cd HaloLive
git lfs install
git lfs pull
```

### Verify LFS Files

To verify that LFS files are correctly downloaded:

```bash
# Check LFS file count
git lfs ls-files | wc -l

# Check file size (should be ~115MB, not 131 bytes)
ls -lh Sources/ThirdPath/SudGIP-pro/SudGIP.xcframework/ios-arm64/SudGIP.framework/SudGIP
```

### Troubleshooting

If files appear as small pointer files (131 bytes), run:

```bash
git lfs fetch --all
git lfs checkout
```

## Requirements

- iOS 16.6+
- Swift 6.0+
- Xcode 15.0+

## License

See LICENSE file for details.

