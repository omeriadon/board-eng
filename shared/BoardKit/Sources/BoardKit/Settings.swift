/// What the board is showing.
public enum BoardMode: UInt8, CaseIterable, Sendable {
	case dither, ambient, music, timer

	public var title: String {
		switch self {
			case .dither: "Dither"
			case .ambient: "Ambient"
			case .music: "Music Mirror"
			case .timer: "Timer"
		}
	}
}

public enum DitherPattern: UInt8, CaseIterable, Sendable {
	case bayer8, bayer4, bayer2, halftone, lines, crosshatch, noise, none

	public var title: String {
		switch self {
			case .bayer8: "Bayer 8×8"
			case .bayer4: "Bayer 4×4"
			case .bayer2: "Bayer 2×2"
			case .halftone: "Halftone"
			case .lines: "Lines"
			case .crosshatch: "Crosshatch"
			case .noise: "Noise"
			case .none: "None"
		}
	}
}

/// How tile heights are chosen.
public enum HeightMode: UInt8, CaseIterable, Sendable {
	/// Each tile rises with the average brightness of its LEDs.
	case brightness
	/// Each tile rises as the inverse of its brightness (dark areas stick out).
	case inverted
	/// All tiles stay retracted; lights only.
	case flat

	public var title: String {
		switch self {
			case .brightness: "Follow Brightness"
			case .inverted: "Inverted"
			case .flat: "Flat"
		}
	}
}

/// Every adjustable property of the dither field. Modelled on Stipple's `DitherSettings`,
/// minus the screen-only knobs (cell size, gap, corner radius, blur), plus tile motion.
public struct DitherSettings: Hashable, Sendable {
	// Wave
	public var waveSpeed: Float = 0.05
	public var waveDirection: Float = 135
	public var waveFrequency: Float = 3
	public var waveAmplitude: Float = 0.3
	public var scale: Float = 1
	public var contrast: Float = 1
	public var brightness: Float = 0

	// Cells
	public var pattern: DitherPattern = .bayer4
	public var ditherStrength: Float = 1
	public var colorLevels: Float = 4

	// Colour
	public var backgroundColor = RGB(0, 0, 0)
	public var palette: [RGB] = [RGB(hex: 0x1FD9FF), RGB(hex: 0x8C2EFF), RGB(hex: 0xFF338C), RGB(hex: 0xFFB82E)]

	// Motion (board only)
	public var heightMode: HeightMode = .brightness
	/// 0...1, scales how far tiles travel.
	public var motionAmount: Float = 0.8
	/// Quiet mode: slower, eased, staggered tile moves.
	public var quietMode = false

	public static let maxPaletteCount = 8
	public static let maxWaveSpeed: Float = 0.066

	public init() {}
}

/// The complete user-facing state of the board.
public struct BoardState: Hashable, Sendable {
	public var isOn = true
	/// Overall LED brightness, 0...1 (the firmware also caps this for power and heat).
	public var brightness: Float = 0.6
	public var mode: BoardMode = .dither
	public var dither = DitherSettings()

	public init() {}
}

#if !hasFeature(Embedded)
	extension BoardMode: Codable {}
	extension DitherPattern: Codable {}
	extension HeightMode: Codable {}
	extension DitherSettings: Codable {}
	extension BoardState: Codable {}
#endif
