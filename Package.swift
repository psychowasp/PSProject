// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let dev = true

//@MainActor
//func pskDependency() -> Package.Dependency {
//    if dev {
//        .package(path: "../PySwiftKit")
//    } else {
//        .package(url: "https://github.com/py-swift/PySwiftKit", branch: "development")
//    }
//}

@MainActor
func getDependencies() -> [Package.Dependency] {[
    //pskDependency(),
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
    
    .package(url: "https://github.com/swiftlang/swift-syntax.git", .upToNextMajor(from: .init(601, 0, 0))),
    .package(url: "https://github.com/kylef/PathKit", .upToNextMajor(from: "1.0.1")),
    .package(url: "https://github.com/jpsim/Yams.git", .upToNextMajor(from: "5.0.6")),
    .package(url: "https://github.com/ITzTravelInTime/SwiftCPUDetect.git", from: "1.3.0"),
    .package(url: "https://github.com/apple/swift-algorithms", .upToNextMajor(from: "1.2.1")),
    
    // pyproject
    .package(url: "https://github.com/LebJe/TOMLKit", .upToNextMajor(from: "0.6.0")),
    .package(path: "./PyProjectToml"),
    .package(url: "https://github.com/Py-Swift/WheelBuilder",branch: "master"),
    // xcode
    .package(path: "./Backends"),
    .package(path: "./PSTools"),
    .package(url: "https://github.com/yonaskolb/XcodeGen.git", from: "2.42.0"),
    .package(url: "https://github.com/Py-Swift/XCAssetsProcessor", .upToNextMajor(from: "0.0.0")),
    .package(url: "https://github.com/tuist/XcodeProj.git", .upToNextMajor(from: "8.24.3")),
    
]}

let targets: [Target] = [
    .executableTarget(
        name: "PSProject",
        dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            .product(name: "WheelBuilder", package: "WheelBuilder"),
            .product(name: "PipRepo", package: "WheelBuilder"),
            "XcodeProjectBuilder",
            "PathKit"
        ],
        swiftSettings: [
            .swiftLanguageMode(.v5)
        ]
    ),
    .target(
        name: "XcodeProjectBuilder",
        dependencies: [
            .product(name: "XcodeGenKit", package: "XcodeGen"),
            .byName(name: "XcodeProj"),
            "PyProjectToml",
            "Backends",
            "PathKit",
            .product(name: "Yams", package: "Yams"),
            .byName(name: "XCAssetsProcessor"),
            .product(name: "Algorithms", package: "swift-algorithms"),
        ],
        swiftSettings: [
            .swiftLanguageMode(.v5)
        ]
    )
]

let package = Package(
    name: "PSProject",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "PSProject", targets: ["PSProject"]),
        .library(name: "XcodeProjectBuilder", targets: ["XcodeProjectBuilder"])
    ],
    dependencies: getDependencies(),
    targets: targets
)
