// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Nuvora",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Nuvora",
            targets: ["Nuvora"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/supabase/supabase-swift.git", from: "2.8.0"),
        .package(url: "https://github.com/stasel/WebRTC.git", from: "118.0.0"),
    ],
    targets: [
        .target(
            name: "Nuvora",
            dependencies: [
                .product(name: "Supabase", package: "supabase-swift"),
                .product(name: "WebRTC", package: "WebRTC"),
            ]
        ),
        .testTarget(
            name: "NuvoraTests",
            dependencies: ["Nuvora"]
        ),
    ]
)
