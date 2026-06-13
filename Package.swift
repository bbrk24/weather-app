// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "WeatherApp",
    platforms: [.macOS(.v13), .iOS(.v16)],
    dependencies: [
        .package(url: "https://github.com/moreSwift/swift-cross-ui.git", revision: "0f77f45889574f035d82540a276a007e11714439"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.11.1")),
    ],
    targets: [
        .target(
            name: "OptimizedMath",
            publicHeadersPath: "include",
            cSettings: [
                .unsafeFlags(["-ffast-math"]),
            ]
        ),
        .target(
            name: "SCUIDependiject",
            dependencies: [
                .product(name: "SwiftCrossUI", package: "swift-cross-ui"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        ),
        .executableTarget(
            name: "WeatherApp",
            dependencies: [
                "OptimizedMath",
                "SCUIDependiject",
                .product(name: "SwiftCrossUI", package: "swift-cross-ui"),
                .product(name: "DefaultBackend", package: "swift-cross-ui"),
                .product(name: "Alamofire", package: "Alamofire"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
            ]
        ),
    ]
)
