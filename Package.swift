// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FoodBlog",
    dependencies: [
        .package(url: "https://github.com/tomieq/BootstrapStarter", from: "1.0.0"),
        .package(url: "https://github.com/tomieq/swifter", from: "2.0.4"),
        .package(url: "https://github.com/tomieq/Template.swift.git", from: "1.5.0")
    ],
    targets: [
        .executableTarget(
            name: "FoodBlog",
            dependencies: [
                .product(name: "BootstrapTemplate", package: "BootstrapStarter"),
                .product(name: "Swifter", package: "Swifter"),
                .product(name: "Template", package: "Template.swift")
            ]),
        .testTarget(
            name: "FoodBlogTests",
            path: "Tests")
    ]
)
