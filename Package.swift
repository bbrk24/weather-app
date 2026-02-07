// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "WeatherApp",
    dependencies: [
        .package(url: "https://github.com/moreSwift/swift-cross-ui.git", revision: "844085ab10485dbe63ad87effd473ca3124d2e2f"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.11.1"))
    ],
    targets: [
        .target(
            name: "OptimizedMath",
            publicHeadersPath: "include",
            cSettings: [
                .unsafeFlags([
                    "-fassociative-math",
                    "-ffast-math",
                    "-ffp-contract=fast",
                    "-fno-protect-parens",
                    "-freciprocal-math",
                ])
            ]
        ),
        .target(
            name: "SCUIDependiject",
            dependencies: [
                .product(name: "SwiftCrossUI", package: "swift-cross-ui"),
            ],
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        ),
        .executableTarget(
            name: "WeatherApp",
            dependencies: [
                "OptimizedMath",
                "SCUIDependiject",
                .product(name: "SwiftCrossUI", package: "swift-cross-ui"),
                .product(name: "DefaultBackend", package: "swift-cross-ui"),
                .product(name: "Alamofire", package: "Alamofire")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
    ]
)
