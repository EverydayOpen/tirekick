// swift-tools-version:6.0
import PackageDescription

// TirekickCore is Foundation-only (builds and tests on Linux/Windows too).
// TirekickMac holds the macOS collectors and hardware-test engines, so it only exists on macOS.
var products: [Product] = [.library(name: "TirekickCore", targets: ["TirekickCore"])]
var targets: [Target] = [
    .target(name: "TirekickCore"),
    // Fixtures are read from disk via #filePath, not bundled (keeps Linux builds warning-free).
    .testTarget(name: "TirekickCoreTests", dependencies: ["TirekickCore"], exclude: ["Fixtures"]),
]

#if os(macOS)
products.append(.library(name: "TirekickMac", targets: ["TirekickMac"]))
targets += [
    .target(name: "TirekickMac", dependencies: ["TirekickCore"]),
    .testTarget(name: "TirekickMacTests", dependencies: ["TirekickMac", "TirekickCore"]),
]
#endif

let package = Package(
    name: "Tirekick",
    // macOS 13 so 2017–2019 Intel Macs (the ones being sold now) can run it. ImageRenderer needs 13.
    platforms: [.macOS(.v13)],
    products: products,
    targets: targets,
    // ponytail: Swift 5 mode keeps strict-concurrency diagnostics as warnings while the Mac code is unverified
    // on real hardware; move to .v6 once CI is green and warnings are cleaned up.
    swiftLanguageModes: [.v5]
)
