import PackageDescription

let package = Package(
    name: "Binson",

    pkgConfig: nil,
    providers: nil,

    products: [
        .library(name: "binson", targets: ["Binson"]),
        .library(name: "binson-static", type: .static, targets: ["Binson"]),
        .library(name: "binson-dynamic", type: .dynamic, targets: ["Binson"])
    ],

    targets: [
            .target(name: "Binson", path: "Binson", dependencies: []),
            .testTarget(name: "Binson-test", path: "BinsonTests", dependencies: ["Binson"])
    ],

    dependencies: [],

    swiftLanguageVersions: [4]
)
