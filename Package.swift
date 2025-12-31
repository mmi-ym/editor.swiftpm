// swift-tools-version: 5.6

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "NovelEditor",
    platforms: [
        .iOS("18.0")
    ],
    products: [
        .iOSApplication(
            name: "NovelEditor",
            targets: ["AppModule"],
            bundleIdentifier: "com.noveleditor.app",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .asset("AppIcon"),
            accentColor: .presetColor(.blue),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "."
        )
    ]
)
