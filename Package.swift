// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ThermalAtlas",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "ThermalAtlas", targets: ["ThermalAtlas"])],
    targets: [
        .executableTarget(name: "ThermalAtlas", path: "Sources/ThermalView"),
        .testTarget(name: "ThermalAtlasTests", dependencies: ["ThermalAtlas"])
    ]
)
