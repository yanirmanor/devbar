// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DevBar",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "DevBar",
            path: "Sources/DevBar"
        )
    ]
)
