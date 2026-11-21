/// The physical layout of the board: `tilesPerSide`² moving tiles, each carrying `ledsPerTileSide`² LEDs.
public struct BoardGeometry: Hashable, Sendable {
	public var tilesPerSide: Int
	public var ledsPerTileSide: Int
	/// Number of discrete heights a tile can sit at (0 = fully retracted).
	public var heightLevels: Int

	public init(tilesPerSide: Int = 5, ledsPerTileSide: Int = 5, heightLevels: Int = 10) {
		self.tilesPerSide = max(1, tilesPerSide)
		self.ledsPerTileSide = max(1, ledsPerTileSide)
		self.heightLevels = max(2, heightLevels)
	}

	/// Pixels along one side of the whole board.
	public var pixelsPerSide: Int { tilesPerSide * ledsPerTileSide }
	public var pixelCount: Int { pixelsPerSide * pixelsPerSide }
	public var tileCount: Int { tilesPerSide * tilesPerSide }
	/// The status bar: one fixed row of LEDs under the grid, separated from it by a gap, as wide as the grid. It holds
	/// the timer and the song progress, so they never cover the picture. It doesn't move.
	public var barPixelCount: Int { pixelsPerSide }
	/// Every LED on the board: the grid plus the status bar.
	public var totalLEDCount: Int { pixelCount + barPixelCount }

	/// The tile (column, row) that owns a pixel.
	public func tile(forPixelColumn column: Int, row: Int) -> (column: Int, row: Int) {
		(column / ledsPerTileSide, row / ledsPerTileSide)
	}

	/// The planned build: 5 × 5 tiles of 5 × 5 LEDs (one premade 5 × 5 module per tile) = 25 × 25 pixels.
	public static let standard = BoardGeometry()

	/// The planned LED current limit: two 5 A buck converters, one for each half of the LED area.
	public static let ledLimitAmps: Double = 10

	/// The limits the layout steppers allow in the apps.
	public static let tileRange = 2 ... 8
	public static let ledRange = 2 ... 8

	/// Amps with every LED full white (WS2812B, about 60 mA each), grid and status bar.
	public var fullWhiteAmps: Double { Double(totalLEDCount) * 0.06 }

	/// Rough full-screen white brightness at a current limit, from the 5 × 5 module's 7.8 mm pitch (estimate, untested
	/// diffuser): about 8,800 nits at 100 % duty, scaled by how much of the full current the limit allows.
	public func fullScreenNits(atLimitAmps limit: Double) -> Int {
		Int((8800 * min(1, limit / fullWhiteAmps)).rounded())
	}
}

#if !hasFeature(Embedded)
	extension BoardGeometry: Codable {}
#endif
