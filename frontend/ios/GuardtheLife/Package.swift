// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GuardtheLife",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "GuardtheLife",
            targets: ["GuardtheLife"]),
    ],
    dependencies: [
        // Add your dependencies here
        // .package(url: "https://github.com/example/package.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "GuardtheLife",
            dependencies: []),
        .testTarget(
            name: "GuardtheLifeTests",
            dependencies: ["GuardtheLife"]),
    ]
) 