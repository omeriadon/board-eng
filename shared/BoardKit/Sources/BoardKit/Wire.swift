// The one wire format. Phone, Mac, server and board all encode and decode with this file, so a change to
// a setting is a compile error everywhere at once instead of a mismatch discovered on the desk.
// It is plain bytes (no Foundation, no Codable), so it works in Embedded Swift on the Pico, and it is
// the same bytes whether they travel over Bluetooth (a GATT write) or Wi-Fi (a WebSocket binary frame).

public struct ByteWriter: Sendable {
	public private(set) var bytes: [UInt8] = []
	public init() {}

	public mutating func u8(_ v: UInt8) { bytes.append(v) }
	public mutating func bool(_ v: Bool) { bytes.append(v ? 1 : 0) }
	public mutating func u16(_ v: UInt16) { bytes.append(UInt8(v & 0xFF)); bytes.append(UInt8(v >> 8)) }
	public mutating func u32(_ v: UInt32) { for shift in [0, 8, 16, 24] { bytes.append(UInt8((v >> UInt32(shift)) & 0xFF)) } }
	public mutating func u64(_ v: UInt64) { u32(UInt32(truncatingIfNeeded: v)); u32(UInt32(truncatingIfNeeded: v >> 32)) }
	public mutating func f32(_ v: Float) { u32(v.bitPattern) }
	public mutating func rgb(_ c: RGB) { let p = c.pixel; u8(p.r); u8(p.g); u8(p.b) }
}

public struct ByteReader: Sendable {
	private let bytes: [UInt8]
	private var index = 0
	/// Set when a read ran past the end. A message that read badly is thrown away whole.
	public private(set) var failed = false

	public init(_ bytes: [UInt8]) { self.bytes = bytes }

	public var isAtEnd: Bool { index == bytes.count }

	public mutating func u8() -> UInt8 {
		guard index < bytes.count else { failed = true; return 0 }
		defer { index += 1 }
		return bytes[index]
	}
	public mutating func bool() -> Bool { u8() != 0 }
	public mutating func u16() -> UInt16 { let a = UInt16(u8()); return a | UInt16(u8()) << 8 }
	public mutating func u32() -> UInt32 {
		var v: UInt32 = 0
		for shift in [0, 8, 16, 24] { v |= UInt32(u8()) << UInt32(shift) }
		return v
	}
	public mutating func u64() -> UInt64 { let low = UInt64(u32()); return low | UInt64(u32()) << 32 }
	public mutating func f32() -> Float { Float(bitPattern: u32()) }
	public mutating func rgb() -> RGB { let r = u8(), g = u8(), b = u8(); return Pixel(r: r, g: g, b: b).rgb }
	/// An enum's raw byte, or `fallback` for a value this version doesn't know.
	public mutating func choice<T: RawRepresentable>(_ type: T.Type, _ fallback: T) -> T where T.RawValue == UInt8 {
		T(rawValue: u8()) ?? fallback
	}
}

// MARK: - Settings

extension DitherSettings {
	func encode(into w: inout ByteWriter) {
		w.f32(waveSpeed); w.f32(waveDirection); w.f32(waveFrequency); w.f32(waveAmplitude)
		w.f32(scale); w.f32(contrast); w.f32(brightness)
		w.u8(pattern.rawValue); w.f32(ditherStrength); w.f32(colorLevels); w.u8(UInt8(truncatingIfNeeded: cellSize))
		w.rgb(waveColor); w.rgb(backgroundColor)
		w.u8(backgroundStyle.rawValue); w.u8(colorPlacement.rawValue); w.u8(squareStyle.rawValue)
		w.bool(colorField); w.f32(blur)
		let colors = palette.prefix(Self.maxPaletteCount)
		w.u8(UInt8(colors.count))
		for c in colors { w.rgb(c) }
	}

	init(from r: inout ByteReader) {
		self.init()
		waveSpeed = r.f32(); waveDirection = r.f32(); waveFrequency = r.f32(); waveAmplitude = r.f32()
		scale = r.f32(); contrast = r.f32(); brightness = r.f32()
		pattern = r.choice(DitherPattern.self, .bayer4); ditherStrength = r.f32(); colorLevels = r.f32()
		cellSize = Int(r.u8())
		waveColor = r.rgb(); backgroundColor = r.rgb()
		backgroundStyle = r.choice(BackgroundStyle.self, .custom)
		colorPlacement = r.choice(ColorPlacement.self, .squares)
		squareStyle = r.choice(SquareStyle.self, .white)
		colorField = r.bool(); blur = r.f32()
		let count = min(Int(r.u8()), Self.maxPaletteCount)
		palette = []
		for _ in 0 ..< count { palette.append(r.rgb()) }
	}
}

extension MotionSettings {
	func encode(into w: inout ByteWriter) {
		w.bool(isEnabled); w.f32(strength); w.u8(source.rawValue); w.f32(speed); w.bool(quietMode)
		w.u8(UInt8(truncatingIfNeeded: maxMovingTiles))
		w.f32(waveSpeed); w.f32(waveDirection); w.f32(waveFrequency); w.f32(waveScale)
		w.u8(UInt8(truncatingIfNeeded: rippleOrigin)); w.f32(rippleSpacing); w.f32(rippleSpeed)
	}

	init(from r: inout ByteReader) {
		self.init()
		isEnabled = r.bool(); strength = r.f32(); source = r.choice(HeightSource.self, .lights)
		speed = r.f32(); quietMode = r.bool(); maxMovingTiles = Int(r.u8())
		waveSpeed = r.f32(); waveDirection = r.f32(); waveFrequency = r.f32(); waveScale = r.f32()
		rippleOrigin = Int(r.u8()); rippleSpacing = r.f32(); rippleSpeed = r.f32()
	}
}

extension TimerSettings {
	func encode(into w: inout ByteWriter) {
		w.u32(UInt32(truncatingIfNeeded: durationSeconds)); w.bool(isRunning); w.u64(endsAtMillis); w.u32(pausedRemainingMillis)
		w.rgb(barColor); w.rgb(trackColor); w.u8(style.rawValue); w.bool(flashWhenDone)
	}

	init(from r: inout ByteReader) {
		self.init()
		durationSeconds = Int(r.u32()); isRunning = r.bool(); endsAtMillis = r.u64(); pausedRemainingMillis = r.u32()
		barColor = r.rgb(); trackColor = r.rgb(); style = r.choice(TimerStyle.self, .drain); flashWhenDone = r.bool()
	}
}

extension AmbientSettings {
	func encode(into w: inout ByteWriter) {
		w.f32(sunrise); w.f32(sunset); w.bool(timeLapse); w.f32(lapseSeconds)
		w.rgb(sunColor); w.rgb(daySky); w.rgb(twilight); w.rgb(nightSky)
		w.f32(glow); w.bool(showStars); w.bool(showMoon)
	}

	init(from r: inout ByteReader) {
		self.init()
		sunrise = r.f32(); sunset = r.f32(); timeLapse = r.bool(); lapseSeconds = r.f32()
		sunColor = r.rgb(); daySky = r.rgb(); twilight = r.rgb(); nightSky = r.rgb()
		glow = r.f32(); showStars = r.bool(); showMoon = r.bool()
	}
}

extension MusicSettings {
	func encode(into w: inout ByteWriter) {
		w.bool(showsProgress); w.f32(progress); w.bool(isPlaying); w.bool(true) /* reserved: was ditherArt */; w.f32(beatJump)
	}

	init(from r: inout ByteReader) {
		self.init()
		showsProgress = r.bool(); progress = r.f32(); isPlaying = r.bool(); _ = r.bool() /* reserved */; beatJump = r.f32()
	}
}

extension AutomationSettings {
	func encode(into w: inout ByteWriter) {
		let list = schedules.prefix(Self.maxSchedules)
		w.u8(UInt8(list.count))
		for x in list {
			w.bool(x.isEnabled); w.u8(x.days); w.u16(UInt16(truncatingIfNeeded: x.startMinute)); w.u16(UInt16(truncatingIfNeeded: x.endMinute))
			w.u8(x.action.rawValue); w.u8(x.mode.rawValue); w.f32(x.dimLevel)
		}
		w.bool(autoBrightness.isEnabled); w.f32(autoBrightness.minimum); w.f32(autoBrightness.maximum)
		w.bool(autoBrightness.offInDark); w.f32(autoBrightness.darkLevel)
		w.bool(presence.isEnabled); w.u8(UInt8(truncatingIfNeeded: presence.idleMinutes)); w.u8(presence.action.rawValue); w.f32(presence.dimLevel)
	}

	init(from r: inout ByteReader) {
		self.init()
		let count = min(Int(r.u8()), Self.maxSchedules)
		schedules = []
		for _ in 0 ..< count {
			var x = Schedule()
			x.isEnabled = r.bool(); x.days = r.u8(); x.startMinute = Int(r.u16()); x.endMinute = Int(r.u16())
			x.action = r.choice(ScheduleAction.self, .off); x.mode = r.choice(BoardMode.self, .ambient); x.dimLevel = r.f32()
			schedules.append(x)
		}
		autoBrightness.isEnabled = r.bool(); autoBrightness.minimum = r.f32(); autoBrightness.maximum = r.f32()
		autoBrightness.offInDark = r.bool(); autoBrightness.darkLevel = r.f32()
		presence.isEnabled = r.bool(); presence.idleMinutes = Int(r.u8()); presence.action = r.choice(AwayAction.self, .dim); presence.dimLevel = r.f32()
	}
}

extension BoardState {
	func encode(into w: inout ByteWriter) {
		w.bool(isOn); w.f32(brightness); w.u8(mode.rawValue)
		dither.encode(into: &w)
		motion.encode(into: &w)
		timer.encode(into: &w)
		ambient.encode(into: &w)
		music.encode(into: &w)
		automation.encode(into: &w)
		w.bool(isAway)
	}

	init(from r: inout ByteReader) {
		self.init()
		isOn = r.bool(); brightness = r.f32(); mode = r.choice(BoardMode.self, .dither)
		dither = DitherSettings(from: &r)
		motion = MotionSettings(from: &r)
		timer = TimerSettings(from: &r)
		ambient = AmbientSettings(from: &r)
		music = MusicSettings(from: &r)
		automation = AutomationSettings(from: &r)
		isAway = r.bool()
	}
}

// MARK: - Messages

/// Orders changes. Every change is stamped with a counter one higher than the newest the sender has seen, plus the
/// sender's own id to settle a tie. A board that gets the same change over Bluetooth and over Wi-Fi sees the same
/// revision twice and applies it once.
public struct Revision: Hashable, Comparable, Sendable {
	public var counter: UInt32
	public var origin: UInt8

	public init(counter: UInt32, origin: UInt8) {
		self.counter = counter
		self.origin = origin
	}

	public static let zero = Revision(counter: 0, origin: 0)

	public static func < (a: Revision, b: Revision) -> Bool {
		a.counter != b.counter ? a.counter < b.counter : a.origin < b.origin
	}
}

/// One-off actions for the Device screen.
public enum BoardCommand: UInt8, Sendable {
	/// Drive every tile to its zero position again.
	case homeAll = 1
	/// Raise and lower the tiles in turn with a test pattern on the lights.
	case testPattern = 2
	case stopTest = 3
	/// Raise one tile (the argument is its index) to check it.
	case testTile = 4
	case reboot = 5
}

/// What the board reports about itself.
public struct BoardStatus: Hashable, Sendable {
	public var firmware: UInt16 = 0
	public var uptimeSeconds: UInt32 = 0
	/// Inside the case (NTC), °C.
	public var temperature: Float = 0
	/// Ambient light (LDR), 0 (dark) ... 1 (bright).
	public var ambientLight: Float = 0
	/// Bit 0: Bluetooth connected. Bit 1: Wi-Fi / server connected.
	public var links: UInt8 = 0
	/// True while the tiles are finding their zero positions.
	public var isHoming = false

	public var hasBluetooth: Bool { links & 1 != 0 }
	public var hasServer: Bool { links & 2 != 0 }

	public init() {}
}

public enum BoardMessage: Hashable, Sendable {
	/// The whole state, always. It's under 150 bytes, and a full state can't be applied half-way or out of order.
	case state(Revision, BoardState)
	case status(BoardStatus)
	/// "Tell me the current state": sent when an app or the board (re)connects.
	case requestState
	/// The current time, from the server, so the board can keep schedules after a power cut.
	case time(unixMillis: UInt64, utcOffsetSeconds: Int32)
	/// Album art for Music Mirror, sent once per track.
	case artwork(Artwork)
	/// A one-off action rather than a setting.
	case command(BoardCommand, argument: UInt8)

	public static let version: UInt8 = 1

	public func encoded() -> [UInt8] {
		var w = ByteWriter()
		w.u8(Self.version)
		switch self {
			case let .state(revision, state):
				w.u8(1); w.u32(revision.counter); w.u8(revision.origin)
				state.encode(into: &w)
			case let .status(s):
				w.u8(2); w.u16(s.firmware); w.u32(s.uptimeSeconds); w.f32(s.temperature); w.f32(s.ambientLight)
				w.u8(s.links); w.bool(s.isHoming)
			case .requestState:
				w.u8(3)
			case let .time(millis, offset):
				w.u8(4); w.u64(millis); w.u32(UInt32(bitPattern: offset))
			case let .artwork(art):
				w.u8(5); w.u32(art.id); w.u8(UInt8(truncatingIfNeeded: art.side))
				for p in art.pixels { w.u8(p.r); w.u8(p.g); w.u8(p.b) }
			case let .command(command, argument):
				w.u8(6); w.u8(command.rawValue); w.u8(argument)
		}
		return w.bytes
	}

	/// Nil for anything malformed, truncated, with trailing bytes, or from a version this build doesn't speak.
	/// Decoded values are clamped into range, so a corrupt message can't drive the board outside its limits.
	public init?(decoding bytes: [UInt8]) {
		var r = ByteReader(bytes)
		guard r.u8() == Self.version else { return nil }
		let message: BoardMessage
		switch r.u8() {
			case 1:
				let revision = Revision(counter: r.u32(), origin: r.u8())
				message = .state(revision, BoardState(from: &r).bounded())
			case 2:
				var s = BoardStatus()
				s.firmware = r.u16(); s.uptimeSeconds = r.u32(); s.temperature = r.f32(); s.ambientLight = r.f32()
				s.links = r.u8(); s.isHoming = r.bool()
				message = .status(s)
			case 3:
				message = .requestState
			case 4:
				message = .time(unixMillis: r.u64(), utcOffsetSeconds: Int32(bitPattern: r.u32()))
			case 5:
				let id = r.u32(), side = Int(r.u8())
				// Side 0 is "no artwork": it clears the last picture.
				guard side <= 64 else { return nil }
				var pixels: [Pixel] = []
				pixels.reserveCapacity(side * side)
				for _ in 0 ..< side * side { let red = r.u8(), green = r.u8(), blue = r.u8(); pixels.append(Pixel(r: red, g: green, b: blue)) }
				message = .artwork(Artwork(id: id, side: side, pixels: pixels))
			case 6:
				guard let command = BoardCommand(rawValue: r.u8()) else { return nil }
				message = .command(command, argument: r.u8())
			default:
				return nil
		}
		guard !r.failed, r.isAtEnd else { return nil }
		self = message
	}
}

/// Keeps one copy of the state in step with every other device, whichever way a change arrives.
/// The apps and the board each hold one.
public struct StateSync: Sendable {
	public private(set) var state: BoardState
	public private(set) var revision: Revision = .zero
	public let origin: UInt8

	public init(origin: UInt8, state: BoardState = BoardState()) {
		self.origin = origin
		self.state = state
	}

	/// This device changed something. Returns the message to send on every link that is up.
	public mutating func change(to new: BoardState) -> BoardMessage {
		state = new.bounded()
		revision = Revision(counter: revision.counter &+ 1, origin: origin)
		return .state(revision, state)
	}

	/// A message arrived. True if it changed the state; false for a duplicate (the same change by the other link)
	/// or for something older than what's already applied.
	@discardableResult
	public mutating func receive(_ message: BoardMessage) -> Bool {
		guard case let .state(incoming, new) = message, incoming > revision else { return false }
		revision = incoming
		state = new
		return true
	}

	/// The state to answer a `requestState` with.
	public var current: BoardMessage { .state(revision, state) }
}

/// Splits a message into pieces that fit a Bluetooth write, and puts them back together. The first byte of each
/// piece is its number (low seven bits) and, in the top bit, whether it is the last. WebSocket frames don't need it.
public enum Framing {
	public static func split(_ bytes: [UInt8], payload: Int) -> [[UInt8]] {
		let size = max(payload, 1)
		var chunks: [[UInt8]] = []
		var index = 0, start = 0
		repeat {
			let end = min(start + size, bytes.count)
			let last = end >= bytes.count
			chunks.append([UInt8(index & 0x7F) | (last ? 0x80 : 0)] + bytes[start ..< end])
			start = end
			index += 1
		} while start < bytes.count && index < 128
		return chunks
	}

	public struct Reassembler: Sendable {
		private var buffer: [UInt8] = []
		private var expected = 0

		public init() {}

		/// The whole message once its last piece arrives; nil until then, and for pieces that arrive out of order.
		public mutating func add(_ chunk: [UInt8]) -> [UInt8]? {
			guard let header = chunk.first else { return nil }
			let index = Int(header & 0x7F), last = header & 0x80 != 0
			if index == 0 { buffer = []; expected = 0 }
			guard index == expected else { buffer = []; expected = 0; return nil }
			buffer.append(contentsOf: chunk.dropFirst())
			expected += 1
			guard last else { return nil }
			defer { buffer = []; expected = 0 }
			return buffer
		}
	}
}
