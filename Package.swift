// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "BGInfoMac",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "BGInfoMac",
            path: "Sources/BGInfoMac",
            linkerSettings: [
                .linkedFramework("CoreWLAN"),
                .linkedFramework("CoreLocation"),
                .linkedFramework("Network"),
                .linkedFramework("IOKit"),
                .linkedFramework("Metal"),
                .linkedFramework("SystemConfiguration")
            ]
        )
    ]
)
