// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FoodBlog",
    targets: [
        .executableTarget(
            name: "FoodBlog"),
        .testTarget(
            name: "FoodBlogTests",
            path: "Tests")
    ]
)
