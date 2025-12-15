// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "HaloFramework",
    defaultLocalization: "en",
    platforms: [
        .iOS("16.6"),
    ],
    products: [
        .library(
            name: "HaloFramework",
            targets: ["HaloFrameworkKit","HaloFramework","SVGAPlayer","SudGIPWrapper","TZImagePickerController","TYCyclePage","FAPaginationLayout"]),
    ],
    dependencies: [
        // QuickVO
        .package(url: "https://github.com/yvws/QuickVO.git", from: "1.5.0"),
        // SnapKit
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.6.0"),
        // RxSwift
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.0.0"),
        // RxDataSources
        .package(url: "https://github.com/RxSwiftCommunity/RxDataSources.git", from: "5.0.0"),
        // RxGesture
        .package(url: "https://github.com/RxSwiftCommunity/RxGesture.git", from: "4.0.0"),
        // Alamofire
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        // Moya
        .package(url: "https://github.com/Moya/Moya.git", from: "15.0.0"),
        // Kingfisher
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0"),
        // KeychainAccess
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.0"),
        // SVProgressHUD
        .package(url: "https://github.com/SVProgressHUD/SVProgressHUD.git", from: "2.0.0"),
        // IQKeyboardManagerSwift
        .package(url: "https://github.com/hackiftekhar/IQKeyboardManager.git", from: "6.5.0"),
        // SwifterSwift
        .package(url: "https://github.com/SwifterSwift/SwifterSwift.git", from: "6.0.0"),
        // SkeletonView
        .package(url: "https://github.com/Juanpe/SkeletonView.git", from: "1.0.0"),
        // Loaf
        .package(url: "https://github.com/schmidyy/Loaf.git", from: "0.7.0"),
        // Lottie
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.0.0"),
        // SDWebImage
        .package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.0.0"),
        // JXSegmentedView
        .package(url: "https://github.com/pujiaxin33/JXSegmentedView.git", from: "1.0.0"),
        // RealmSwift
        .package(url: "https://github.com/realm/realm-swift.git", exact: "10.44.0"),
        // SwiftyGif
        .package(url: "https://github.com/kirualex/SwiftyGif.git", from: "5.0.0"),
        // MJRefresh
        .package(url: "https://github.com/CoderMJLee/MJRefresh.git", from: "3.7.9"),
        // MJExtension
        .package(url: "https://github.com/CoderMJLee/MJExtension.git", from: "3.4.1"),
        // FSPlayerLib
        .package(url: "https://github.com/motian30/FSPlayerLib.git", from: "1.0.2"),
        // GoogleSignIn
        .package(url: "https://github.com/google/GoogleSignIn-iOS.git", from: "9.0.0"),
        // PLCrashReporter
        .package(url: "https://github.com/microsoft/plcrashreporter.git", from: "1.12.0"),
        // QVLiveP2PLib
        .package(url: "https://github.com/motian30/QVLiveP2PLib.git", from: "1.0.1"),
    ],
    targets: [
        // Binary target for HaloFramework
        .binaryTarget(
            name: "HaloFramework",
            url: "https://github.com/rogertan30/HaloLive/releases/download/1.0.1/HaloFramework.xcframework.zip",
            checksum: "f3fdc6c3267df593cc3fbdb7839ff105f1fdae9f707eecd6a123d7ee8d420f09"
        ),
        // Binary target for SudGIP
        .binaryTarget(
            name: "SudGIP",
            url: "https://github.com/rogertan30/HaloLive/releases/download/1.0.1/SudGIP.xcframework.zip",
            checksum: "f8f3b68b94ee21a70671f3afa3c5b5c266662f41732c5a0befa43c3b41e61506"
        ),
        // Protobuf target
        .target(
            name: "Protobuf",
            path: "Sources/ThirdPath/Protobuf",
            exclude: [],
            resources: [],
            publicHeadersPath: "objectivec",
            cSettings: [
                .headerSearchPath("objectivec"),
                .headerSearchPath("objectivec/google/protobuf"),
                .unsafeFlags(["-fmodules", "-fcxx-modules", "-fno-objc-arc"])
            ],
            linkerSettings: [
                .linkedFramework("Foundation")
            ]
        ),
        // SSZipArchive target
        .target(
            name: "SSZipArchive",
            path: "Sources/ThirdPath/SSZipArchive",
            exclude: [],
            resources: [],
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("."),
                .define("HAVE_WZAES"),
                .define("HAVE_AES"),
                .define("HAVE_SHA1"),
                .define("HAVE_SHA256"),
                .define("HAVE_CRC32"),
                .define("HAVE_PKCRYPT"),
                .define("MZ_ZIP_NO_ENCRYPTION", to: "0"),
                .define("MZ_ZIP_NO_SIGNING", to: "0"),
                .unsafeFlags(["-fmodules", "-fcxx-modules"])
            ],
            linkerSettings: [
                .linkedFramework("Foundation"),
                .linkedFramework("Security")
            ]
        ),
        // SVGAPlayer target
        .target(
            name: "SVGAPlayer",
            dependencies: ["Protobuf", "SSZipArchive"],
            path: "Sources/ThirdPath/SVGAPlayer",
            exclude: [],
            resources: [],
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("../SSZipArchive"),
                .unsafeFlags(["-fmodules", "-fcxx-modules"])
            ],
            linkerSettings: [
                .linkedFramework("UIKit"),
                .linkedFramework("Foundation"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("QuartzCore")
            ]
        ),
        // SudGIPWrapper target
        .target(
            name: "SudGIPWrapper",
            dependencies: ["SudGIP", .product(name: "MJExtension", package: "MJExtension")],
            path: "Sources/ThirdPath/SudGIPWrapper-pro/SudGIPWrapper",
            exclude: [],
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("Decorator"),
                .headerSearchPath("Model"),
                .headerSearchPath("State"),
                .unsafeFlags(["-fmodules", "-fcxx-modules"])
            ],
            linkerSettings: [
                .linkedFramework("UIKit"),
                .linkedFramework("Foundation")
            ]
        ),
        // TZImagePickerController target
        .target(
            name: "TZImagePickerController",
            path: "Sources/ThirdPath/TZImagePickerController",
            exclude: [],
            resources: [
                .process("TZImagePickerController.bundle")
            ],
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("pbobjc"),
                .unsafeFlags(["-fmodules", "-fcxx-modules"])
            ],
            linkerSettings: [
                .linkedFramework("UIKit"),
                .linkedFramework("Photos")
            ]
        ),
        .target(
            name: "TYCyclePage",
            path: "Sources/ThirdPath/TYCyclePage",
            exclude: [],
            resources: [],
            publicHeadersPath: ".",
            cSettings: [
                .headerSearchPath("."),
                .unsafeFlags(["-fmodules", "-fcxx-modules"])
            ],
            linkerSettings: [
                .linkedFramework("UIKit"),
                .linkedFramework("Foundation")
            ]
        ),
        .target(
            name: "FAPaginationLayout",
            path: "Sources/ThirdPath/FAPaginationLayout",
            exclude: [],
            resources: [],
            linkerSettings: [
                .linkedFramework("UIKit"),
                .linkedFramework("Foundation")
            ]
        ),
        .target(
            name: "HaloFrameworkKit",
            dependencies: [
                // QuickVO
                .product(name: "QuickVO", package: "QuickVO"),
                // SnapKit
                .product(name: "SnapKit", package: "SnapKit"),
                // RxSwift
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "RxCocoa", package: "RxSwift"),
                // RxDataSources
                .product(name: "RxDataSources", package: "RxDataSources"),
                // RxGesture
                .product(name: "RxGesture", package: "RxGesture"),
                // Alamofire
                .product(name: "Alamofire", package: "Alamofire"),
                // Moya
                .product(name: "RxMoya", package: "Moya"),
                // Kingfisher
                .product(name: "Kingfisher", package: "Kingfisher"),
                // KeychainAccess
                .product(name: "KeychainAccess", package: "KeychainAccess"),
                // SVProgressHUD
                .product(name: "SVProgressHUD", package: "SVProgressHUD"),
                // IQKeyboardManagerSwift
                .product(name: "IQKeyboardManagerSwift", package: "IQKeyboardManager"),
                // SwifterSwift
                .product(name: "SwifterSwift", package: "SwifterSwift"),
                // SkeletonView
                .product(name: "SkeletonView", package: "SkeletonView"),
                // Loaf
                .product(name: "Loaf", package: "Loaf"),
                // Lottie
                .product(name: "Lottie", package: "lottie-ios"),
                // SDWebImage
                .product(name: "SDWebImage", package: "SDWebImage"),
                // JXSegmentedView
                .product(name: "JXSegmentedView", package: "JXSegmentedView"),
                // RealmSwift
                .product(name: "RealmSwift", package: "realm-swift"),
                // SwiftyGif
                .product(name: "SwiftyGif", package: "SwiftyGif"),
                // MJRefresh
                .product(name: "MJRefresh", package: "MJRefresh"),
                // MJExtension
                .product(name: "MJExtension", package: "MJExtension"),
                // FSPlayerLib
                .product(name: "FSPlayerLib", package: "FSPlayerLib"),
                // GoogleSignIn
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                // PLCrashReporter
                .product(name: "CrashReporter", package: "plcrashreporter"),
                // QVLiveP2PLib
                .product(name: "QVLiveP2P", package: "QVLiveP2PLib"),
                // HaloFramework binary
                "HaloFramework",
                // Third party targets
                "SVGAPlayer",
                "SudGIPWrapper",
                "TZImagePickerController",
                "TYCyclePage",
            ]
        ),
    ],
    swiftLanguageModes: [.v5]
)

