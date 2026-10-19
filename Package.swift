// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BoardWatch",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "BoardWatch", targets: ["BoardWatch"])
    ],
    targets: [
        .executableTarget(
            name: "BoardWatch",
            path: "Sources/BoardWatch"
        ),
    ]
)
