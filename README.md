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

## Large Binary Files

Due to GitHub's 100MB file size limit, some large binary files are distributed via GitHub Releases.

### Required Files

The following file exceeds GitHub's size limit and must be downloaded separately:

- `Sources/ThirdPath/SudGIP-pro/SudGIP.xcframework/ios-arm64/SudGIP.framework/SudGIP` (115 MB)

### How to Get Large Files

1. Go to the [Releases page](https://github.com/rogertan30/HaloLive/releases)
2. Download the latest release archive
3. Extract the file to the correct location in your local repository:
   ```bash
   # Extract the file to the correct path
   unzip -j release.zip "SudGIP.framework/SudGIP" -d Sources/ThirdPath/SudGIP-pro/SudGIP.xcframework/ios-arm64/SudGIP.framework/
   ```

Alternatively, you can use the provided script:

```bash
./scripts/download-large-files.sh
```

## Requirements

- iOS 16.6+
- Swift 6.0+
- Xcode 15.0+

## License

See LICENSE file for details.

