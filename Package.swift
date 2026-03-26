// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "RippleClick",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .target(
            name: "RippleClickLib",
            path: "Sources/RippleClick",
            exclude: ["Resources"]
        ),
        .executableTarget(
            name: "RippleClick",
            dependencies: ["RippleClickLib"],
            path: "Sources/RippleClickApp"
        ),
        .testTarget(
            name: "RippleClickTests",
            dependencies: ["RippleClickLib"],
            path: "Tests/RippleClickTests"
        ),
    ]
)
