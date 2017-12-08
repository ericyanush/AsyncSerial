// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AsyncSerial",
    products: [
        .library(
            name: "AsyncSerial",
            targets: ["AsyncSerial"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AsyncSerial",
            dependencies: []),
        .testTarget(
            name: "AsyncSerialTests",
            dependencies: ["AsyncSerial"]),
    ]
)
