// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VietFlow",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "VietFlow",
            targets: ["VietFlowApp"]
        ),
        .library(
            name: "VietFlowEngine",
            targets: ["VietFlowEngine"]
        ),
        .library(
            name: "VietFlowState",
            targets: ["VietFlowState"]
        ),
        .library(
            name: "VietFlowEventTap",
            targets: ["VietFlowEventTap"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "VietFlowEngine",
            dependencies: [],
            path: "Sources/VietFlowEngine"
        ),
        .target(
            name: "VietFlowState",
            dependencies: ["VietFlowEngine"],
            path: "Sources/VietFlowState"
        ),
        .target(
            name: "VietFlowEventTap",
            dependencies: ["VietFlowEngine", "VietFlowState"],
            path: "Sources/VietFlowEventTap"
        ),
        .executableTarget(
            name: "VietFlowApp",
            dependencies: ["VietFlowEngine", "VietFlowState", "VietFlowEventTap"],
            path: "Sources/VietFlowApp"
        ),
        .testTarget(
            name: "VietFlowEngineTests",
            dependencies: ["VietFlowEngine"],
            path: "Tests/VietFlowEngineTests"
        ),
        .testTarget(
            name: "VietFlowTerminalBufferTests",
            dependencies: ["VietFlowEngine"],
            path: "Tests/VietFlowTerminalBufferTests"
        ),
    ]
)
