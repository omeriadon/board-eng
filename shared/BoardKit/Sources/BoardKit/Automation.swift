// Schedules, automatic brightness and "away" behaviour. They live in the state, so the board follows them on its own
// when no app is awake. `Automation.effective` is the one function that decides what the board actually does.

public enum ScheduleAction: UInt8, CaseIterable, Sendable {
	case off, dim, switchMode

	public var title: String {
		switch self {
			case .off: "Turn Off"
			case .dim: "Dim"
			case .switchMode: "Switch Mode"
		}
	}
}

public struct Schedule: Hashable, Sendable {
	public var isEnabled = true
	/// Bit 0 = Monday ... bit 6 = Sunday.
	public var days: UInt8 = 0b0011111
	public var startMinute: Int = 22 * 60
	public var endMinute: Int = 7 * 60
	public var action: ScheduleAction = .off
	public var mode: BoardMode = .ambient
	public var dimLevel: Float = 0.2

	public init() {}

	public func runs(on weekday: Int) -> Bool { days & (1 << UInt8(weekday % 7)) != 0 }

	/// A window that passes midnight belongs to the day it starts on.
	public func isActive(weekday: Int, minuteOfDay: Int) -> Bool {
		guard isEnabled, startMinute != endMinute else { return false }
		if startMinute < endMinute {
			return runs(on: weekday) && minuteOfDay >= startMinute && minuteOfDay < endMinute
		}
		return (runs(on: weekday) && minuteOfDay >= startMinute) || (runs(on: (weekday + 6) % 7) && minuteOfDay < endMinute)
	}

	public func bounded() -> Schedule {
		var v = self
		v.days &= 0b1111111
		v.startMinute = min(max(startMinute, 0), 1439)
		v.endMinute = min(max(endMinute, 0), 1439)
		v.dimLevel = limit(dimLevel, 0.2, 0, 1)
		return v
	}
}

/// Dims the board in a dark room and brightens it in a bright one, using the board's own light sensor.
public struct AutoBrightness: Hashable, Sendable {
	public var isEnabled = false
	/// Brightness multiplier in the darkest / brightest room.
	public var minimum: Float = 0.15
	public var maximum: Float = 1
	/// Turn the board off when the room is darker than `darkLevel`.
	public var offInDark = false
	public var darkLevel: Float = 0.05

	public init() {}

	public func bounded() -> AutoBrightness {
		var v = self
		v.minimum = limit(minimum, 0.15, 0, 1)
		v.maximum = limit(maximum, 1, v.minimum, 1)
		v.darkLevel = limit(darkLevel, 0.05, 0, 1)
		return v
	}
}

public enum AwayAction: UInt8, CaseIterable, Sendable {
	case dim, off, stillOnly

	public var title: String {
		switch self {
			case .dim: "Dim"
			case .off: "Turn Off"
			case .stillOnly: "Stop Moving"
		}
	}
}

/// What the board does while you're away from the desk. The Mac decides when that is (no keyboard or mouse for
/// `idleMinutes`) and sets `BoardState.isAway`.
public struct PresenceSettings: Hashable, Sendable {
	public var isEnabled = true
	public var idleMinutes: Int = 5
	public var action: AwayAction = .dim
	public var dimLevel: Float = 0.15

	public init() {}

	public func bounded() -> PresenceSettings {
		var v = self
		v.idleMinutes = min(max(idleMinutes, 1), 120)
		v.dimLevel = limit(dimLevel, 0.15, 0, 1)
		return v
	}
}

public struct AutomationSettings: Hashable, Sendable {
	public var schedules: [Schedule] = []
	public var autoBrightness = AutoBrightness()
	public var presence = PresenceSettings()

	public static let maxSchedules = 8

	public init() {}

	public func bounded() -> AutomationSettings {
		var v = self
		v.schedules = schedules.prefix(Self.maxSchedules).map { $0.bounded() }
		v.autoBrightness = autoBrightness.bounded()
		v.presence = presence.bounded()
		return v
	}
}

/// What time it is and how bright the room is: everything a frame depends on besides the settings.
public struct RenderContext: Sendable {
	public var unixMillis: UInt64
	public var utcOffsetSeconds: Int32
	/// The board's light sensor, 0 (dark) ... 1 (bright).
	public var ambientLight: Float

	public init(unixMillis: UInt64 = 0, utcOffsetSeconds: Int32 = 0, ambientLight: Float = 1) {
		self.unixMillis = unixMillis
		self.utcOffsetSeconds = utcOffsetSeconds
		self.ambientLight = ambientLight
	}

	private var localSeconds: Int64 { Int64(unixMillis / 1000) + Int64(utcOffsetSeconds) }
	private var dayNumber: Int64 { Self.floorDiv(localSeconds, 86400) }

	/// 0 = Monday ... 6 = Sunday (1 January 1970 was a Thursday).
	public var weekday: Int { Int(((dayNumber + 3) % 7 + 7) % 7) }
	public var secondOfDay: Int { Int(localSeconds - dayNumber * 86400) }
	public var minuteOfDay: Int { secondOfDay / 60 }
	public var hourOfDay: Float { Float(secondOfDay) / 3600 }

	private static func floorDiv(_ a: Int64, _ b: Int64) -> Int64 { a >= 0 ? a / b : -((-a + b - 1) / b) }
}

public enum Automation {
	/// The state the board really acts on: the user's state with schedules, automatic brightness and "away" applied.
	public static func effective(_ raw: BoardState, context c: RenderContext) -> BoardState {
		var s = raw
		let a = raw.automation

		if c.unixMillis > 0 {
			for schedule in a.schedules where schedule.isActive(weekday: c.weekday, minuteOfDay: c.minuteOfDay) {
				switch schedule.action {
					case .off: s.isOn = false
					case .dim: s.brightness *= schedule.dimLevel
					case .switchMode: s.mode = schedule.mode
				}
			}
		}

		if a.autoBrightness.isEnabled {
			let b = a.autoBrightness
			s.brightness *= b.minimum + (b.maximum - b.minimum) * clamp(c.ambientLight, 0, 1)
			if b.offInDark, c.ambientLight < b.darkLevel { s.isOn = false }
		}

		if raw.isAway, a.presence.isEnabled {
			switch a.presence.action {
				case .dim: s.brightness *= a.presence.dimLevel
				case .off: s.isOn = false
				case .stillOnly: s.motion.isEnabled = false
			}
		}
		return s
	}
}

#if !hasFeature(Embedded)
	extension ScheduleAction: Codable {}
	extension Schedule: Codable {}
	extension AutoBrightness: Codable {}
	extension AwayAction: Codable {}
	extension PresenceSettings: Codable {}
	extension AutomationSettings: Codable {}
#endif
