// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GoBoard",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "GoBoard",
            targets: ["GoBoard"]
        ),
        .library(
            name: "GoAgent",
            targets: ["GoAgent"]
        ),
        .executable(
            name: "PlayGoBots",
            targets: ["PlayGoBots"]
        ),
        .executable(
            name: "SelfPlay",
            targets: ["SelfPlay"]
        ),
        .executable(
            name: "TrainGoBots",
            targets: ["TrainGoBots"]
        ),.executable(
            name: "EvaluateGoBots",
            targets: ["EvaluateGoBots"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log", from: "1.8.0"),
        .package(url: "https://github.com/ml-explore/mlx-swift", from: "0.10.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.8.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "GoBoard",
            dependencies: [
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .target(
            name: "GoAgent",
            dependencies: [
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXNN", package: "mlx-swift"),
                .product(name: "MLXOptimizers", package: "mlx-swift"),
                .product(name: "Logging", package: "swift-log"),
                "GoBoard"
            ]
        ),
        .target(
            name: "GoBotsSupport",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                "GoBoard"
            ]
        ),
        .executableTarget(
            name: "PlayGoBots",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "GoAgent",
                "GoBotsSupport",
            ]
        ),
        .executableTarget(
            name: "SelfPlay",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXNN", package: "mlx-swift"),
                .product(name: "MLXOptimizers", package: "mlx-swift"),
                "GoAgent",
                "GoBotsSupport",
            ]
        ),
        .executableTarget(
            name: "TrainGoBots",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXNN", package: "mlx-swift"),
                .product(name: "MLXOptimizers", package: "mlx-swift"),
                "GoAgent",
                "GoBotsSupport",
            ]
        ),
        .executableTarget(
            name: "EvaluateGoBots",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "GoAgent",
                "GoBotsSupport",
            ]
        ),
        .testTarget(
            name: "GoBoardTests",
            dependencies: ["GoBoard"]
        ),
        .testTarget(
            name: "ScoringTests",
            dependencies: ["GoBoard"]
        ),
        .testTarget(
            name: "GoAgentTests",
            dependencies: ["GoAgent", "GoBoard"]
        ),
    ]
)
