/// The physical layout of the board: `tilesPerSide`² moving tiles, each carrying `ledsPerTileSide`² LEDs.
public struct BoardGeometry: Hashable, Sendable {
	public var tilesPerSide: Int
	public var ledsPerTileSide: Int
	/// Number of discrete heights a tile can sit at (0 = fully retracted).
	public var heightLevels: Int

	public init(tilesPerSide: Int = 5, ledsPerTileSide: Int = 4, heightLevels: Int = 10) {
		self.tilesPerSide = max(1, tilesPerSide)
		self.ledsPerTileSide = max(1, ledsPerTileSide)
		self.heightLevels = max(2, heightLevels)
	}

	/// Pixels along one side of the whole board.
	public var pixelsPerSide: Int { tilesPerSide * ledsPerTileSide }
	public var pixelCount: Int { pixelsPerSide * pixelsPerSide }
	public var tileCount: Int { tilesPerSide * tilesPerSide }

	/// The tile (column, row) that owns a pixel.
	public func tile(forPixelColumn column: Int, row: Int) -> (column: Int, row: Int) {
		(column / ledsPerTileSide, row / ledsPerTileSide)
	}

	public static let standard = BoardGeometry()
}

#if !hasFeature(Embedded)
	extension BoardGeometry: Codable {}
#endif
