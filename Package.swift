// swift-tools-version:4.0
import PackageDescription

_ = Package(
    name: "Binson",

    products: [
        .library(name: "binson", targets: ["Binson"])
    ],

    targets: [
            .target(name: "Binson", path: "Binson"),
            .testTarget(name: "Binson-test", dependencies: ["Binson"], path: "BinsonTests")
    ],

    swiftLanguageVersions: [4]
  )
