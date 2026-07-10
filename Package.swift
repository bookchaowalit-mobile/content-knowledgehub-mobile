// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Knowledgehub",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Knowledgehub", targets: ["Knowledgehub"])
    ],
    targets: [
        .target(name: "Knowledgehub", path: "Sources")
    ]
)
