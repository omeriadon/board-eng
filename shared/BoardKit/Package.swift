// swift-tools-version: 6.2
import PackageDescription

let package = Package(
	name: "BoardKit",
	platforms: [.iOS(.v26), .macOS(.v26), .watchOS(.v26)],
	products: [
		.library(name: "BoardKit", targets: ["BoardKit"]),
	],
	targets: [
		// No Foundation, no SIMD, no libm: this target must also compile as Embedded Swift for the Pico W.
		.target(name: "BoardKit"),
		.testTarget(name: "BoardKitTests", dependencies: ["BoardKit"]),
	]
)
