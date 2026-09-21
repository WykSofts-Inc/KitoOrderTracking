// swift-tools-version: 5.9
//
//  Package.swift
//  KitoOrderTracking
//
//  Created by Wycliff on 9/21/26.
//  Copyright © 2026 wyksoftsinc.com. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "KitoOrderTracking",
    platforms: [.iOS(.v17)],
    products: [.library(name: "KitoOrderTracking", targets: ["KitoOrderTracking"])],
    dependencies: [
        .package(url: "https://github.com/WykSofts-Inc/KitoCore.git", from: "1.0.0"),
    ],
    targets: [
        .target(name: "KitoOrderTracking", dependencies: [.product(name: "KitoCore", package: "KitoCore")]),
        .testTarget(name: "KitoOrderTrackingTests", dependencies: ["KitoOrderTracking"]),
    ]
)
