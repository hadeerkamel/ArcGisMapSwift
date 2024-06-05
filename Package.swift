// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ArcGISMapSwift",
    platforms: [
           .iOS(.v17)
       ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ArcGISMapSwift",
            targets: ["ArcGISMapSwift"]),
    ],
    dependencies: [
        .package(
            url: "https://github.com/Esri/arcgis-maps-sdk-swift",
            from: "200.4.0" // Use the appropriate version
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ArcGISMapSwift"//,
//            dependencies: [
//                            .product(name: "ArcGIS", package: "arcgis-maps-sdk-swift"),
//                            .product(name: "arcgis-maps-sdk-swift-toolkit", package: "arcgis-maps-sdk-swift")
//                        ]
        ),
        .testTarget(
            name: "ArcGISMapSwiftTests",
            dependencies: ["ArcGISMapSwift"]),
    ]
)
