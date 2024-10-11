// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FoodBlog",
    dependencies: [
        .package(url: "https://github.com/tomieq/BootstrapStarter", revision: "6c58c3d"),
        .package(url: "https://github.com/tomieq/swifter", revision: "b5a4759"),
        .package(url: "https://github.com/tomieq/Template.swift.git", from: "1.5.0"),
        .package(url: "https://github.com/twostraws/SwiftGD", branch: "main"),
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.3")
    ],
    targets: [
        .executableTarget(
            name: "FoodBlog",
            dependencies: [
                .product(name: "BootstrapTemplate", package: "BootstrapStarter"),
                .product(name: "Swifter", package: "Swifter"),
                .product(name: "Template", package: "Template.swift"),
                .product(name: "SwiftGD", package: "SwiftGD"),
                .product(name: "SQLite", package: "SQLite.swift")
            ]),
        .testTarget(
            name: "FoodBlogTests",
            dependencies: [
                "FoodBlog",
                .product(name: "SwiftGD", package: "SwiftGD"),
                .product(name: "SQLite", package: "SQLite.swift")
            ],
            path: "Tests")
    ]
)
