// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "RippleClick",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .target(
            name: "RippleClickLib",
            path: "Sources/RippleClick",
            resources: [.process("Resources")]
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
