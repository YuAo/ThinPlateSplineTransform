// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ThinPlateSplineTransform",
    platforms: [.macOS(.v10_13), .iOS(.v10), .watchOS(.v5), .tvOS(.v10)],
    products: [
        .library(
            name: "ThinPlateSplineTransform",
            targets: ["ThinPlateSplineTransform"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "ThinPlateSplineTransform",
            dependencies: ["ThinPlateSplineTransformCore"]),
        .target(
            name: "ThinPlateSplineTransformCore",
            dependencies: []),
        .testTarget(
            name: "ThinPlateSplineTransformTests",
            dependencies: ["ThinPlateSplineTransform"]),
    ]
)
