// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "IpRiskLight",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "IpRiskLight"
        ),
        .testTarget(
            name: "IpRiskLightTests",
            dependencies: ["IpRiskLight"]
        ),
    ]
)
