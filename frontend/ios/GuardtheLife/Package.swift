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
        // Firebase
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0"),
        
        // Stripe
        .package(url: "https://github.com/stripe/stripe-ios.git", from: "23.0.0"),
        
        // Socket.IO
        .package(url: "https://github.com/socketio/socket.io-client-swift.git", from: "16.0.0"),
        
        // Location and Maps
        .package(url: "https://github.com/airbnb/lottie-ios.git", from: "4.0.0"),
        
        // Networking and JSON
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.0.0"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "5.0.0"),
        
        // Keychain for secure storage
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.0.0"),
        
        // Image loading and caching
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.0.0")
    ],
    targets: [
        .target(
            name: "GuardtheLife",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "Stripe", package: "stripe-ios"),
                .product(name: "SocketIO", package: "socket.io-client-swift"),
                .product(name: "Lottie", package: "lottie-ios"),
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "SwiftyJSON", package: "SwiftyJSON"),
                .product(name: "KeychainAccess", package: "KeychainAccess"),
                .product(name: "Kingfisher", package: "Kingfisher")
            ]),
        .testTarget(
            name: "GuardtheLifeTests",
            dependencies: ["GuardtheLife"]),
    ]
) 