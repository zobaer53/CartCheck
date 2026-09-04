// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "CartCheckKit",
    // macOS is pinned to the same major version as iOS (not just "some
    // modern macOS") because CartCheckData depends on FoundationModels and
    // the SwiftData @ModelActor macro, both iOS/macOS 26 APIs — this lets
    // `swift test` exercise CartCheckData natively on the host.
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "CartCheckDomain", targets: ["CartCheckDomain"]),
        .library(name: "CartCheckData", targets: ["CartCheckData"]),
    ],
    targets: [
        .target(name: "CartCheckDomain"),
        .target(name: "CartCheckData", dependencies: ["CartCheckDomain"]),
        .testTarget(name: "CartCheckDomainTests", dependencies: ["CartCheckDomain"]),
        .testTarget(name: "CartCheckDataTests", dependencies: ["CartCheckData", "CartCheckDomain"]),
    ]
)
