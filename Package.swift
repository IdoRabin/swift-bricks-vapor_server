// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "bricks_vapor",
    platforms: [
        .macOS(.v13),
    ],
    dependencies: [
        // Vapor
        .package(url: "https://github.com/vapor/vapor.git", from: "4.106.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.12.0"),
        .package(url: "https://github.com/vapor/fluent-postgres-driver.git", from: "2.10.0"),
        .package(url: "https://github.com/vapor/leaf.git", from: "4.4.0"),

        // 3rd pary

        // In-House pakcages
        // >>> .package(path: "../../xcode/MNUtils/MNUtils"), // from: "0.0.2"
        .package(path: "../../xcode/MNSettings2/MNSettings2"), // from: "0.0.2"
        // >>> .package(path: "../../vapor/MNVaporUtils/"), // from: "0.0.2"
        .package(path: "../../vapor/RRabac") // from: "0.0.1"
    ],
    targets: [
        .executableTarget(
            name: "BricksVapor",
            dependencies: [
                // Vapor
                .product(name: "Fluent", package: "fluent"),
                .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
                .product(name: "Leaf", package: "leaf"),
                .product(name: "Vapor", package: "vapor"),

                // In-House pakcages
                // >>> .product(name: "MNUtils", package: "MNUtils"),
                .product(name: "MNSettings", package: "MNSettings2"),
                // >>> .product(name: "MNVaporUtils", package: "MNVaporUtils"),
                .product(name: "RRabac", package: "RRabac"),
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
        .testTarget(name: "BricksVaporTests",
                    dependencies: [
                        .target(name: "BricksVapor"),
                        .product(name: "XCTVapor", package: "vapor"),

                        // Workaround for https://github.com/apple/swift-package-manager/issues/6940
//                        .product(name: "Vapor", package: "vapor"),
//                        .product(name: "Fluent", package: "Fluent"),
//                        .product(name: "FluentPostgresDriver", package: "fluent-postgres-driver"),
//                        .product(name: "Leaf", package: "leaf"),
                    ],
                    swiftSettings: [
                        .define("TESTING"),
                        .define("VAPOR"), // Vapor framework, to distinguish in classes that are also used in iOS / macOS.
                        .define("PRODUCTION", .when(configuration: .release)),
                        .define("DEBUG", .when(configuration: .debug)),
                    ]),
    ],
    swiftLanguageVersions: [.v5]
)
