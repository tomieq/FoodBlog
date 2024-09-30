// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FoodBlog",
    dependencies: [
        .package(url: "https://github.com/tomieq/BootstrapStarter", from: "1.0.1"),
        .package(url: "https://github.com/tomieq/swifter", from: "2.0.4"),
        .package(url: "https://github.com/tomieq/Template.swift.git", from: "1.5.0"),
        .package(url: "https://github.com/twostraws/SwiftGD", branch: "main")
    ],
    targets: [
        .executableTarget(
            name: "FoodBlog",
            dependencies: [
                .product(name: "BootstrapTemplate", package: "BootstrapStarter"),
                .product(name: "Swifter", package: "Swifter"),
                .product(name: "Template", package: "Template.swift"),
                .product(name: "SwiftGD", package: "SwiftGD")
            ]),
        .testTarget(
            name: "FoodBlogTests",
            path: "Tests")
    ]
)
