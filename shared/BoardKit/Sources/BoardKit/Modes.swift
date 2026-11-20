// The settings for the three non-dither modes: Timer, Ambient (the sun through the day) and Music Mirror.

public enum TimerStyle: UInt8, CaseIterable, Sendable {
	/// The bar starts full and shrinks.
	case drain
	/// The bar starts empty and grows.
	case fill

	public var title: String { self == .drain ? "Drain" : "Fill" }
}

/// The timer bar: it fills the status bar under the grid, and the grid keeps showing the dither field. Time is absolute (`endsAtMillis`, unix time), so every device and the board agree
/// on what's left without sending a message every second.
public struct TimerSettings: Hashable, Sendable {
	public var durationSeconds: Int = 300
	public var isRunning = false
	/// Unix milliseconds when the timer ends, while running.
	public var endsAtMillis: UInt64 = 0
	/// What was left when it was paused (0 when it isn't paused).
	public var pausedRemainingMillis: UInt32 = 0
	public var barColor = RGB(hex: 0x1FD9FF)
	public var trackColor = RGB(0.07, 0.07, 0.1)
	public var style: TimerStyle = .drain
	/// Blink the bar for a while when time is up.
	public var flashWhenDone = true

	public static let maxDuration = 24 * 3600
	/// How long the bar blinks after the end.
	public static let flashMillis: UInt64 = 30_000

	public init() {}

	public var totalMillis: UInt32 { UInt32(min(max(durationSeconds, 1), Self.maxDuration)) * 1000 }
	public var isPaused: Bool { !isRunning && pausedRemainingMillis > 0 }

	public func remainingMillis(now: UInt64) -> UInt32 {
		if isRunning { return endsAtMillis > now ? UInt32(min(endsAtMillis - now, UInt64(UInt32.max))) : 0 }
		return pausedRemainingMillis > 0 ? pausedRemainingMillis : totalMillis
	}

	public func isFinished(now: UInt64) -> Bool { isRunning && now >= endsAtMillis }

	/// Fraction of the time still left, 0...1.
	public func fractionRemaining(now: UInt64) -> Float {
		clamp(Float(remainingMillis(now: now)) / Float(totalMillis), 0, 1)
	}

	public mutating func start(now: UInt64) {
		let remaining = pausedRemainingMillis > 0 ? pausedRemainingMillis : totalMillis
		endsAtMillis = now + UInt64(remaining)
		pausedRemainingMillis = 0
		isRunning = true
	}

	public mutating func pause(now: UInt64) {
		guard isRunning, !isFinished(now: now) else { return }
		pausedRemainingMillis = max(remainingMillis(now: now), 1)
		isRunning = false
	}

	public mutating func reset() {
		isRunning = false
		endsAtMillis = 0
		pausedRemainingMillis = 0
	}

	public func bounded() -> TimerSettings {
		var v = self
		v.durationSeconds = min(max(durationSeconds, 1), Self.maxDuration)
		v.barColor = barColor.clamped
		v.trackColor = trackColor.clamped
		if pausedRemainingMillis > v.totalMillis { v.pausedRemainingMillis = v.totalMillis }
		return v
	}
}

/// The sun (and moon) crossing the board through the day, with a sky that follows it.
public struct AmbientSettings: Hashable, Sendable {
	/// Hours of the day, 0...24.
	public var sunrise: Float = 6.5
	public var sunset: Float = 18.5
	/// Plays a whole day in `lapseSeconds` instead of following the clock.
	public var timeLapse = false
	public var lapseSeconds: Float = 60
	public var sunColor = RGB(hex: 0xFFC94A)
	public var daySky = RGB(hex: 0x2E7BE0)
	public var twilight = RGB(hex: 0xFF6A3D)
	public var nightSky = RGB(hex: 0x050818)
	/// How far the sun's light spreads into the sky, 0...1.
	public var glow: Float = 0.6
	public var showStars = true
	public var showMoon = true

	public init() {}

	public func bounded() -> AmbientSettings {
		var v = self
		v.sunrise = limit(sunrise, 6.5, 0, 12)
		v.sunset = limit(sunset, 18.5, 12, 24)
		v.lapseSeconds = limit(lapseSeconds, 60, 5, 600)
		v.sunColor = sunColor.clamped; v.daySky = daySky.clamped
		v.twilight = twilight.clamped; v.nightSky = nightSky.clamped
		v.glow = limit(glow, 0.6, 0, 1)
		return v
	}
}

/// Mirrors what's playing: the album art on the board, and a progress bar on the status bar under the grid.
public struct MusicSettings: Hashable, Sendable {
	public var showsProgress = true
	/// Playback position, 0...1. The Mac updates it about once a second.
	public var progress: Float = 0
	public var isPlaying = false
	/// How hard tiles jump on each beat, 0...1 (0 = off).
	public var beatJump: Float = 0

	public init() {}

	public func bounded() -> MusicSettings {
		var v = self
		v.progress = limit(progress, 0, 0, 1)
		v.beatJump = limit(beatJump, 0, 0, 1)
		return v
	}
}

/// The album art, already shrunk to the board's pixels by the Mac. Sent on its own, once per track, because it is
/// far bigger than the settings.
public struct Artwork: Hashable, Sendable {
	public var id: UInt32
	public var side: Int
	public var pixels: [Pixel]

	public init(id: UInt32, side: Int, pixels: [Pixel]) {
		self.id = id
		self.side = side
		self.pixels = pixels
	}

	public var isValid: Bool { side > 0 && side <= 64 && pixels.count == side * side }
}

#if !hasFeature(Embedded)
	extension TimerStyle: Codable {}
	extension TimerSettings: Codable {}
	extension AmbientSettings: Codable {}
	extension MusicSettings: Codable {}
#endif
