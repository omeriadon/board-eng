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

public enum BackgroundStyle: UInt8, CaseIterable, Sendable {
	case custom, black, white, dim

	public var title: String {
		switch self {
			case .custom: "Custom"
			case .black: "Black"
			case .white: "White"
			case .dim: "Dimmed Wave"
		}
	}
}

public enum ColorPlacement: UInt8, CaseIterable, Sendable {
	case squares, background

	public var title: String { self == .squares ? "Squares" : "Background" }
}

public enum SquareStyle: UInt8, CaseIterable, Sendable {
	case white, black

	public var title: String { self == .white ? "White" : "Black" }
}

/// Every adjustable property of the light field. Modelled on Stipple's `DitherSettings`, minus what only
/// makes sense on a screen (gap, corner radius, joined squares, touch, always-on, intro, frame rate).
public struct DitherSettings: Hashable, Sendable {
	// Wave
	public var waveSpeed: Float = 0.03
	/// Degrees, snapped to the eight compass points.
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
	/// LEDs per cell side: 1 (every LED), 2 or 4 (a whole tile). The board's own version of Stipple's cell size.
	public var cellSize: Int = 1

	// Colour
	public var waveColor = RGB(0.12, 0.85, 1)
	public var backgroundColor = RGB(0.02, 0.01, 0.08)
	public var backgroundStyle: BackgroundStyle = .custom
	public var colorPlacement: ColorPlacement = .squares
	public var squareStyle: SquareStyle = .white
	public var palette: [RGB] = [RGB(hex: 0x1FD9FF), RGB(hex: 0x8C2EFF), RGB(hex: 0xFF338C), RGB(hex: 0xFFB82E)]
	/// Blends the palette across the board instead of by brightness.
	public var colorField = false

	// Composition
	/// 0 (crisp) ... 1 (soft): mixes each LED with its neighbours.
	public var blur: Float = 0

	public static let maxPaletteCount = 8
	public static let maxWaveSpeed: Float = 0.04
	public static let cellSizes = [1, 2, 4]

	public init() {}

	public static func snappedDirection(_ degrees: Float) -> Float {
		guard degrees == degrees, abs(degrees) < 1e6 else { return 135 }
		var n = degrees - (degrees / 360).rounded(.down) * 360
		if n < 0 { n += 360 }
		let snapped = (n / 45).rounded() * 45
		return snapped >= 360 ? 0 : snapped
	}

	/// Clamps every value into what the renderer supports. Used on everything that arrives over the wire.
	public func bounded() -> DitherSettings {
		var v = self
		v.waveSpeed = limit(waveSpeed, 0.03, 0, Self.maxWaveSpeed)
		v.waveDirection = Self.snappedDirection(waveDirection)
		v.waveFrequency = limit(waveFrequency, 3, 0.01, 12)
		v.waveAmplitude = limit(waveAmplitude, 0.3, 0, 1)
		v.scale = limit(scale, 1, 0.05, 32)
		v.contrast = limit(contrast, 1, 0.01, 8)
		v.brightness = limit(brightness, 0, -1, 1)
		v.ditherStrength = limit(ditherStrength, 1, 0, 1)
		v.colorLevels = limit(colorLevels, 4, 2, 16)
		v.cellSize = cellSize >= 4 ? 4 : (cellSize >= 2 ? 2 : 1)
		v.waveColor = waveColor.clamped
		v.backgroundColor = backgroundColor.clamped
		if palette.count > Self.maxPaletteCount { v.palette = Array(palette[0 ..< Self.maxPaletteCount]) }
		v.palette = v.palette.map { $0.clamped }
		v.blur = limit(blur, 0, 0, 1)
		return v
	}
}

/// What drives how high each tile sits.
public enum HeightSource: UInt8, CaseIterable, Sendable {
	/// Tiles rise with the brightness of their LEDs.
	case lights
	/// Tiles rise where their LEDs are dark.
	case invertedLights
	/// Its own slow wave, independent of the lights.
	case wave
	/// Rings spreading from a chosen point.
	case ripple
	/// Tiles stay put.
	case off

	public var title: String {
		switch self {
			case .lights: "Follow Lights"
			case .invertedLights: "Opposite of Lights"
			case .wave: "Own Wave"
			case .ripple: "Ripples"
			case .off: "Still"
		}
	}
}

/// The physical jumping. Applies to every mode and is independent of what the LEDs show.
public struct MotionSettings: Hashable, Sendable {
	/// Master switch. Off, every tile rests flat and the motors sit idle.
	public var isEnabled = true
	/// How far tiles travel, 0...1 of their stroke.
	public var strength: Float = 0.8
	public var source: HeightSource = .lights
	/// How quickly a tile moves to a new height, 0...1.
	public var speed: Float = 0.5
	/// Slower, eased, fewer tiles at once, so the clicks never stack up.
	public var quietMode = false
	/// Most tiles allowed to move in the same instant (power and noise).
	public var maxMovingTiles: Int = 6

	// Own wave
	public var waveSpeed: Float = 0.03
	public var waveDirection: Float = 45
	public var waveFrequency: Float = 1.5
	public var waveScale: Float = 1

	// Ripples
	/// One of nine spots on a 3 × 3 grid, row-major: 0 top-left ... 4 centre ... 8 bottom-right.
	public var rippleOrigin: Int = 4
	/// Distance between rings, in tiles.
	public var rippleSpacing: Float = 3
	/// Rings per second, 0...1.
	public var rippleSpeed: Float = 0.4

	public static let maxWaveSpeed: Float = 0.04

	public init() {}

	public func bounded() -> MotionSettings {
		var v = self
		v.strength = limit(strength, 0.8, 0, 1)
		v.speed = limit(speed, 0.5, 0, 1)
		v.maxMovingTiles = min(max(maxMovingTiles, 1), 16)
		v.waveSpeed = limit(waveSpeed, 0.03, 0, Self.maxWaveSpeed)
		v.waveDirection = DitherSettings.snappedDirection(waveDirection)
		v.waveFrequency = limit(waveFrequency, 1.5, 0.1, 6)
		v.waveScale = limit(waveScale, 1, 0.1, 8)
		v.rippleOrigin = min(max(rippleOrigin, 0), 8)
		v.rippleSpacing = limit(rippleSpacing, 3, 1, 8)
		v.rippleSpeed = limit(rippleSpeed, 0.4, 0, 1)
		return v
	}
}

/// The complete user-facing state of the board.
public struct BoardState: Hashable, Sendable {
	public var isOn = true
	/// Overall LED brightness, 0...1 (the firmware also caps this for power and heat).
	public var brightness: Float = 0.6
	public var mode: BoardMode = .dither
	public var dither = DitherSettings()
	public var motion = MotionSettings()
	public var timer = TimerSettings()
	public var ambient = AmbientSettings()
	public var music = MusicSettings()
	public var automation = AutomationSettings()
	/// Set by the Mac when you've stepped away from the desk; the board applies the "away" behaviour.
	public var isAway = false

	public init() {}

	public func bounded() -> BoardState {
		var v = self
		v.brightness = limit(brightness, 0.6, 0, 1)
		v.dither = dither.bounded()
		v.motion = motion.bounded()
		v.timer = timer.bounded()
		v.ambient = ambient.bounded()
		v.music = music.bounded()
		v.automation = automation.bounded()
		return v
	}
}

/// NaN-safe clamp.
@inline(__always) func limit(_ v: Float, _ fallback: Float, _ lo: Float, _ hi: Float) -> Float {
	let x = (v == v && abs(v) < 1e9) ? v : fallback
	return x < lo ? lo : (x > hi ? hi : x)
}

#if !hasFeature(Embedded)
	extension BoardMode: Codable {}
	extension DitherPattern: Codable {}
	extension BackgroundStyle: Codable {}
	extension ColorPlacement: Codable {}
	extension SquareStyle: Codable {}
	extension HeightSource: Codable {}
	extension DitherSettings: Codable {}
	extension MotionSettings: Codable {}
	extension BoardState: Codable {}
#endif
