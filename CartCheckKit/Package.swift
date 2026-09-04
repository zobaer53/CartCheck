// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "CartCheckKit",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "CartCheckDomain", targets: ["CartCheckDomain"]),
        .library(name: "CartCheckData", targets: ["CartCheckData"]),
    ],
    targets: [
        .target(name: "CartCheckDomain"),
        .target(name: "CartCheckData", dependencies: ["CartCheckDomain"]),
        .testTarget(name: "CartCheckDomainTests", dependencies: ["CartCheckDomain"]),
    ]
)
