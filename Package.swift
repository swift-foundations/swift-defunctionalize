// swift-tools-version: 6.3

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "swift-defunctionalize",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26),
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
        .package(path: "../../swift-primitives/swift-optic-primitives"),
        .package(path: "../../swift-primitives/swift-finite-primitives"),
    ],
    targets: [
        .target(
            name: "Defunctionalize",
            dependencies: [
                "Defunctionalize Macros",
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
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "Defunctionalize Test Support",
            dependencies: [
                "Defunctionalize",
            ],
            path: "Tests/Support"
        ),
        .testTarget(
            name: "Defunctionalize Tests",
            dependencies: [
                "Defunctionalize"
            ]
        )
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
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
