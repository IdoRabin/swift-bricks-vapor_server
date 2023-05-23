// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "bricks_server",
    platforms: [
        .macOS(.v12)
    ],
    dependencies: [
        // 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "4.76.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.8.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.7.2"),
        .package(url: "https://github.com/vapor/leaf.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Leaf", package: "leaf"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "JWT", package: "jwt"),
            ],
            swiftSettings: [
                // Enables better optimizations when building in Release
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release)),
                
                .define("PRODUCTION", .when(configuration: .release)),
                .define("DEBUG", .when(configuration: .debug)),
                .define("VAPOR"), // Vapor framework, to distinguish in classes that are also used in iOS / macOS.
            ]
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                .target(name: "App"),
                .product(name: "XCTVapor", package: "vapor"),
            ],
            swiftSettings: [
                .define("TESTING"),
            ]
        )
    ]
)
