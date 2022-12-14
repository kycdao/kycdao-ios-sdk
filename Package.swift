// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "kycDAO-SDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "KycDao",
            targets: ["KycDao"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/WalletConnect/WalletConnectSwift", .upToNextMajor(from: "1.7.0")),
        .package(url: "https://github.com/argentlabs/web3.swift", .upToNextMajor(from: "1.4.0")),
        .package(url: "https://github.com/persona-id/inquiry-ios-2", .upToNextMajor(from: "2.3.0")),
        .package(url: "https://github.com/CombineCommunity/CombineExt.git", .upToNextMajor(from: "1.8.1"))
    ],
    targets: [
        .target(
            name: "KycDao",
            dependencies: [
                "WalletConnectSwift",
                .productItem(name: "PersonaInquirySDK2", package: "inquiry-ios-2", condition: nil),
                "CombineExt",
                "web3.swift"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "kycDAO-SDKTests",
            dependencies: ["KycDao"],
            path: "Tests",
            exclude: ["CheckCocoaPodsQualityIndexes.rb"]
        )
    ],
    swiftLanguageVersions: [.v5]
)
