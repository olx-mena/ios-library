// swift-tools-version:5.3

// Copyright Airship and Contributors

import PackageDescription

let package = Package(
    name: "Airship",
    defaultLocalization: "en",
    platforms: [.macOS(.v10_15), .iOS(.v11), .tvOS(.v11)],
    products: [
        .library(
            name: "Airship",
            targets: ["AirshipCore", "AirshipAutomation", "AirshipMessageCenter", "AirshipExtendedActions"]),
        .library(
            name: "AirshipCore",
            targets: ["AirshipCore"]),
        .library(
            name: "AirshipAutomation",
            targets: ["AirshipAutomation"]),
        .library(
            name: "AirshipMessageCenter",
            targets: ["AirshipMessageCenter"]),
        .library(
            name: "AirshipExtendedActions",
            targets: ["AirshipExtendedActions"]),
        .library(
            name: "AirshipLocation",
            targets: ["AirshipLocation"]),
        .library(
            name: "AirshipAccengage",
            targets: ["AirshipAccengage"]),
        .library(
            name: "AirshipNotificationContentExtension",
            targets: ["AirshipNotificationContentExtension"]),
        .library(
            name: "AirshipNotificationServiceExtension",
            targets: ["AirshipNotificationServiceExtension"])
    ],
    targets: [
        .target(name: "AirshipCore",
                path: "Airship/AirshipCore",
                exclude: ["Resources/Info.plist",
                          "Source/Public/AirshipCore.h",
                          "generate_header_imports.sh",
                          "Info.plist",
                          "Tests"],
                sources : ["Source"],
                resources: [
                    .process("Resources")],
                publicHeadersPath: "Source/Public",
                cSettings: [
                    .headerSearchPath("Source/Internal")],
                linkerSettings: [
                    //Frameworks
                    .linkedFramework("Network"),
                    .linkedFramework("UserNotifications"),
                    .linkedFramework("UserNotifications"),
                    .linkedFramework("CFNetwork"),
                    .linkedFramework("CoreGraphics"),
                    .linkedFramework("Foundation"),
                    .linkedFramework("Security"),
                    .linkedFramework("SystemConfiguration"),
                    .linkedFramework("UIKit"),
                    .linkedFramework("CoreData"),
                    .linkedFramework("WebKit", .when(platforms: [.iOS])),
                    .linkedFramework("CoreTelephony", .when(platforms: [.iOS])),
                    //Libraries
                    .linkedLibrary("z"),
                    .linkedLibrary("sqlite3")
                ]
        ),
        .target(name:"AirshipAutomation",
                dependencies: [.target(name: "AirshipCore")],
                path: "Airship/AirshipAutomation",
                exclude: ["Resources/Info.plist",
                          "Source/AirshipAutomation.h",
                          "generate_header_imports.sh",
                          "Info.plist"],
                sources : ["Source"],
                resources: [
                    .process("Resources")],
                publicHeadersPath: "Source/Public",
                cSettings: [
                    .headerSearchPath("Source")],
                linkerSettings: [
                    .linkedFramework("UIKit")]
        ),
        .target(name:"AirshipMessageCenter",
                dependencies: [.target(name: "AirshipCore")],
                path: "Airship/AirshipMessageCenter",
                exclude: ["Resources/Info.plist",
                          "Source/AirshipMessageCenter.h",
                          "generate_header_imports.sh",
                          "Info.plist"],
                sources : ["Source"],
                resources: [
                    .process("Resources")],
                publicHeadersPath: "Source/Public",
                cSettings: [
                    .headerSearchPath("Source"),
                    .headerSearchPath("Source/Inbox"),
                    .headerSearchPath("Source/Inbox/Data"),
                    .headerSearchPath("Source/User"),]
        ),
        .target(name:"AirshipExtendedActions",
                dependencies: [.target(name: "AirshipCore")],
                path: "Airship/AirshipExtendedActions",
                exclude: ["Resources/Info.plist",
                          "Source/AirshipExtendedActions.h",
                          "generate_header_imports.sh",
                          "Info.plist"],
                sources : ["Source"],
                resources: [
                    .process("Resources")
                ],
                publicHeadersPath: "Source/Public",
                cSettings: [
                    .headerSearchPath("Source/RateApp")],
                linkerSettings: [
                    .linkedFramework("StoreKit")]
        ),
        .target(name:"AirshipLocation",
                dependencies: [.target(name: "AirshipCore")],
                path: "Airship/AirshipLocation",
                exclude: ["Source/AirshipLocation.h",
                          "Info.plist"],
                sources : ["Source"],
                publicHeadersPath: "Source/Public",
                cSettings: [
                    .headerSearchPath("Source")],
                linkerSettings: [
                    .linkedFramework("CoreLocation")]
        ),
        .target(name:"AirshipAccengage",
                dependencies: [.target(name: "AirshipCore")],
                path: "Airship/AirshipAccengage",
                exclude: ["Source/AirshipAccengage.h",
                          "Info.plist",
                          "Tests"],
                sources : ["Source"],
                resources: [
                    .process("Resources")],
                publicHeadersPath: "Source/Public",
                cSettings: [
                    .headerSearchPath("Source"),
                    .headerSearchPath("Source/AccengageInternal")]
        ),
        .target(name:"AirshipNotificationContentExtension",
                path: "AirshipExtensions/AirshipNotificationContentExtension",
                exclude: ["Source/AirshipNotificationContentExtension.h",
                          "Info.plist",
                          "Tests"],
                sources : ["Source"],
                resources: [
                    .process("Resources")],
                publicHeadersPath: "Source/Public"
        ),
        .target(name:"AirshipNotificationServiceExtension",
                path: "AirshipExtensions/AirshipNotificationServiceExtension",
                exclude: ["Source/AirshipNotificationServiceExtension.h",
                          "Info.plist",
                          "Tests"],
                sources : ["Source"],
                resources: [
                    .process("Resources")],
                publicHeadersPath: "Source"
        )
    ]
)
