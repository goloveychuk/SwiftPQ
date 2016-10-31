import PackageDescription

let package = Package(
    name: "PurePostgres",
    dependencies: [
        .Package(url: "https://github.com/Zewo/TCP", majorVersion: 0, minor: 14),
        .Package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", majorVersion: 0),
        .Package(url: "https://github.com/Zewo/Reflection.git", majorVersion: 0, minor: 14),
    ]
)
