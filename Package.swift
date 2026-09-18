// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "QingXing",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(
            url: "https://github.com/mrkai77/Luminare",
            revision: "c6b60e3b24dac0f51c25d0dcda27a45cc37e1e93"
        )
    ],
    targets: [
        .target(name: "QingXingCore"),
        .executableTarget(
            name: "QingXing",
            dependencies: [
                "QingXingCore",
                .product(name: "Luminare", package: "Luminare")
            ]
        ),
        .testTarget(
            name: "QingXingTests",
            dependencies: ["QingXingCore"]
        )
    ]
)
