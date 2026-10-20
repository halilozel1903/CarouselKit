// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "CarouselKit",
    platforms: [
        .iOS(.v17),
        .tvOS(.v17),
        // macOS only so `swift test` runs on CI; the carousels are made for iPhone and Apple TV.
        .macOS(.v14),
    ],
    products: [
        .library(name: "CarouselKit", targets: ["CarouselKit"]),
    ],
    targets: [
        .target(name: "CarouselKit"),
        .testTarget(name: "CarouselKitTests", dependencies: ["CarouselKit"]),
    ]
)
