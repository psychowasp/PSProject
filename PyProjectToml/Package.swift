// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PyProjectToml",
    platforms: [
        .macOS(.v15),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "PyProjectToml",
            targets: ["PyProjectToml"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kylef/PathKit", .upToNextMajor(from: "1.0.1")),
        .package(url: "https://github.com/LebJe/TOMLKit", .upToNextMajor(from: "0.6.0")),
        .package(path: "./Backends"),
        .package(url: "https://github.com/PerfectlySoft/Perfect-INIParser.git", from: "3.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "PyProjectToml",
            dependencies: [
                "TOMLKit",
                "PathKit",
                "Backends",
                .product(name: "INIParser", package: "perfect-iniparser"),
            ]
        ),

    ]
)
