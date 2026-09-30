// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Knowledgehub",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "KnowledgehubCore", targets: ["KnowledgehubCore"]),
        .library(name: "KnowledgehubUI", targets: ["KnowledgehubUI"]),
    ],
    targets: [
        // Foundation-only domain logic; no SwiftUI so it also builds on Linux.
        .target(name: "KnowledgehubCore", path: "Sources/KnowledgehubCore"),
        .target(name: "KnowledgehubUI", dependencies: ["KnowledgehubCore"], path: "Sources/KnowledgehubUI"),
        .testTarget(name: "KnowledgehubCoreTests", dependencies: ["KnowledgehubCore"], path: "Tests/KnowledgehubCoreTests"),
    ]
)
