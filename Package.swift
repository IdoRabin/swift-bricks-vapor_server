// swift-tools-version:5.8
import PackageDescription

let package = Package(
    // 💧 A Vapor server-side Swift web f ramework.
    name: "bricks_server",
    platforms: [
        .macOS(.v13),
    ],
    dependencies: [
        // 3Rd party
        .package(url: "https://github.com/vapor/vapor.git", from: "4.76.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.8.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.7.2"),
        .package(url: "https://github.com/vapor/leaf.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/jwt.git", from: "4.0.0"),
        
         // In-House pakcages
        .package(path: "../../xcode/DSLogger"),
        .package(path: "../../xcode/MNUtils/MNUtils"), // from: "0.0.2"
        .package(path: "../../vapor/MNVaporUtils/"), // from: "0.0.2"
        // .package(path: "../../vapor/RRabac"),
    ],
    targets: [
        .executableTarget(
            name: "BricksServer",
            dependencies: [
                // 3Rd party
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Leaf", package: "leaf"),
                .product(name: "Vapor", package: "vapor"),
                .product(name: "JWT", package: "jwt"),
                
                // In-House pakcages
                .product(name: "DSLogger", package: "DSLogger"),
                .product(name: "MNUtils", package: "MNUtils"),
                .product(name: "MNVaporUtils", package: "MNVaporUtils"),
                // .product(name: "RRabac", package: "RRabac"),
            ],
            swiftSettings: [
                // Enables better optimizations when building in Release
                .unsafeFlags(["-cross-module-optimization"], .when(configuration: .release)),
                
                .define("PRODUCTION", .when(configuration: .release)),
                .define("DEBUG", .when(configuration: .debug)),
                .define("VAPOR"), // Vapor framework, to distinguish in classes that are also used in iOS / macOS.
                .define("NIO"),
            ]
        ),
        .testTarget(
            name: "AppTests",
            dependencies: [
                .target(name: "BricksServer"),
                .product(name: "XCTVapor", package: "vapor"),
            ],
            swiftSettings: [
                .define("TESTING"),
            ]
        )
    ],
    
    swiftLanguageVersions: [.v5]
)
