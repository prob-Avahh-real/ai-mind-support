// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AiMindSupport",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "AiMindSupport",
            targets: ["AiMindSupport"]
        )
    ],
    dependencies: [
        // Add external dependencies here if needed
        // .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.0.0")
    ],
    targets: [
        .target(
            name: "AiMindSupport",
            dependencies: [],
            path: "AiMindSupport"
        )
    ]
)