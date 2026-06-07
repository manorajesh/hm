// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "hm",
    platforms: [
        .macOS(.v26),
    ],
    targets: [
        .executableTarget(
            name: "hm"
        ),
        .testTarget(
            name: "hmTests",
            dependencies: ["hm"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
