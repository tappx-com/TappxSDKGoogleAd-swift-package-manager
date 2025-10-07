// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TappxGoogleAdsAdapter",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "TappxGoogleAdsAdapter",
            targets: ["TappxGoogleAdsAdapter"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tappx-com/TappxSDK-swift-package-manager.git", from: "4.2.6"),
        .package(url: "https://github.com/googleads/swift-package-manager-google-mobile-ads.git", .upToNextMajor(from: "12.0.0"))
    ],
    targets: [
        .target(
            name: "TappxGoogleAdsAdapter",
            dependencies: [
                .product(name: "TappxSDK", package: "TappxSDK-swift-package-manager"),
                .product(name: "GoogleMobileAds", package: "swift-package-manager-google-mobile-ads")
            ],
            path: "TappxGoogleAdsAdapter"
        ),

    ]
)
