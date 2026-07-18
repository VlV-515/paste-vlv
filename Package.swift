// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "paste-vlv",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Paste-vlv", targets: ["PasteVLv"])
    ],
    targets: [
        .executableTarget(
            name: "PasteVLv",
            path: "Sources/PasteVLv"
        )
    ]
)
