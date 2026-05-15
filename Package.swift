// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Wayfound",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Wayfound", targets: ["Wayfound"])
    ],
    targets: [
        .executableTarget(
            name: "Wayfound",
            path: "Sources/Wayfound"
        ),
        .testTarget(
            name: "WayfoundTests",
            dependencies: ["Wayfound"],
            path: "Tests/WayfoundTests"
        )
    ]
)
