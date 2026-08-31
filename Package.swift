// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpenbaseAgentUI",
    platforms: [
        .iOS(.v16),
    ],
    products: [
        .library(
            name: "OpenbaseAgentUI",
            targets: ["OpenbaseAgentUI"]
        ),
    ],
    targets: [
        .target(name: "OpenbaseAgentUI"),
        .testTarget(
            name: "OpenbaseAgentUITests",
            dependencies: ["OpenbaseAgentUI"]
        ),
    ]
)
