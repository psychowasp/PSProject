// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Backends",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Backends",
            targets: ["Backends"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/kylef/PathKit", .upToNextMajor(from: "1.0.1")),
        .package(url: "https://github.com/ITzTravelInTime/SwiftCPUDetect.git", from: "1.3.0"),
        .package(url: "https://github.com/yonaskolb/XcodeGen.git", from: "2.42.0"),
        .package(url: "https://github.com/apple/swift-algorithms", .upToNextMajor(from: "1.2.1")),
        .package(path: "./PSTools")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Backends",
            dependencies: [
                "PathKit",
                .product(name: "XcodeGenKit", package: "XcodeGen"),
                .product(name: "ProjectSpec", package: "XcodeGen"),
                "PSTools",
                .byName(name: "SwiftCPUDetect"),
                .product(name: "Algorithms", package: "swift-algorithms"),
            ]
        ),

    ]
)
