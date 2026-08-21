// swift-tools-version: 6.4

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "swift-defunctionalize",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(
            name: "Defunctionalize",
            targets: ["Defunctionalize"]
        ),
        .library(
            name: "Defunctionalize Test Support",
            targets: ["Defunctionalize Test Support"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "602.0.0"..<"603.0.0"),
        .package(
            url: "https://github.com/swift-primitives/swift-optic-primitives.git",
            branch: "main"
        ),
        .package(
            url: "https://github.com/swift-primitives/swift-finite-primitives.git",
            branch: "main"
        ),
    ],
    targets: [
        .target(
            name: "Defunctionalize",
            dependencies: [
                "Defunctionalize Macros"
            ]
        ),
        .target(
            name: "Defunctionalize Macros",
            dependencies: [
                "Defunctionalize Macros Implementation",
                .product(name: "Optic Primitives", package: "swift-optic-primitives"),
                .product(name: "Finite Primitives", package: "swift-finite-primitives"),
            ]
        ),
        .macro(
            name: "Defunctionalize Macros Implementation",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "Defunctionalize Test Support",
            dependencies: [
                "Defunctionalize"
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Defunctionalize Tests",
            dependencies: [
                "Defunctionalize",
                // A `.macro` target propagates none of its own product
                // dependencies into the test bundle Swift Build links, so the
                // macro implementation's SwiftSyntax symbols have to be named
                // on the test target that pulls it in.
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
