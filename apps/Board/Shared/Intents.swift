import AppIntents
import BoardKit

// Actions for the Shortcuts app and Siri. They change the same store the app shows; the store sends the change on
// every connected link. A shortcut may wake the app with nothing connected yet, so each intent waits a moment for a
// link to come up (the store re-sends its state when one does).

extension BoardStore {
	/// Give a freshly launched app a few seconds to reach the board before the intent finishes.
	func deliver() async {
		for _ in 0 ..< 40 where link.connected.isEmpty { try? await Task.sleep(for: .milliseconds(100)) }
		try? await Task.sleep(for: .milliseconds(300))
	}
}

enum BoardModeOption: String, AppEnum {
	case dither, ambient, music, timer

	static let typeDisplayRepresentation: TypeDisplayRepresentation = "Board Mode"
	static let caseDisplayRepresentations: [BoardModeOption: DisplayRepresentation] = [
		.dither: "Dither", .ambient: "Ambient", .music: "Music Mirror", .timer: "Timer",
	]

	var mode: BoardMode {
		switch self {
			case .dither: .dither
			case .ambient: .ambient
			case .music: .music
			case .timer: .timer
		}
	}
}

struct ThemeEntity: AppEntity {
	static let typeDisplayRepresentation: TypeDisplayRepresentation = "Colour Theme"
	static let defaultQuery = ThemeQuery()

	var id: String
	var name: String
	var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }

	init(_ theme: ColorTheme) {
		id = theme.id
		name = theme.name
	}
}

struct ThemeQuery: EntityQuery {
	@MainActor func entities(for identifiers: [String]) async throws -> [ThemeEntity] {
		BoardStore.shared.presets.allThemes.filter { identifiers.contains($0.id) }.map(ThemeEntity.init)
	}

	@MainActor func suggestedEntities() async throws -> [ThemeEntity] {
		BoardStore.shared.presets.allThemes.map(ThemeEntity.init)
	}
}

struct SetBoardPowerIntent: AppIntent {
	static let title: LocalizedStringResource = "Turn Board On or Off"
	static let description = IntentDescription("Turns the dither board's lights on or off.")
	static let openAppWhenRun = false

	@Parameter(title: "On", default: true) var isOn: Bool

	static var parameterSummary: some ParameterSummary { Summary("Turn board \(\.$isOn)") }

	@MainActor func perform() async throws -> some IntentResult {
		let store = BoardStore.shared
		store.state.isOn = isOn
		await store.deliver()
		return .result()
	}
}

struct SetBoardBrightnessIntent: AppIntent {
	static let title: LocalizedStringResource = "Set Board Brightness"

	@Parameter(title: "Brightness", default: 60, inclusiveRange: (0, 100)) var percent: Int

	static var parameterSummary: some ParameterSummary { Summary("Set board brightness to \(\.$percent)%") }

	@MainActor func perform() async throws -> some IntentResult {
		let store = BoardStore.shared
		store.state.brightness = Float(percent) / 100
		await store.deliver()
		return .result()
	}
}

struct SetBoardModeIntent: AppIntent {
	static let title: LocalizedStringResource = "Set Board Mode"

	@Parameter(title: "Mode") var mode: BoardModeOption

	static var parameterSummary: some ParameterSummary { Summary("Show \(\.$mode) on the board") }

	@MainActor func perform() async throws -> some IntentResult {
		let store = BoardStore.shared
		store.state.mode = mode.mode
		await store.deliver()
		return .result()
	}
}

struct SetBoardJumpingIntent: AppIntent {
	static let title: LocalizedStringResource = "Turn Board Jumping On or Off"
	static let description = IntentDescription("Turns the tiles' physical jumping on or off. The lights keep going.")

	@Parameter(title: "Jumping", default: true) var isOn: Bool

	static var parameterSummary: some ParameterSummary { Summary("Turn board jumping \(\.$isOn)") }

	@MainActor func perform() async throws -> some IntentResult {
		let store = BoardStore.shared
		store.state.motion.isEnabled = isOn
		await store.deliver()
		return .result()
	}
}

struct ApplyBoardThemeIntent: AppIntent {
	static let title: LocalizedStringResource = "Apply Board Colour Theme"

	@Parameter(title: "Theme") var theme: ThemeEntity

	static var parameterSummary: some ParameterSummary { Summary("Apply \(\.$theme) to the board") }

	@MainActor func perform() async throws -> some IntentResult {
		let store = BoardStore.shared
		guard let found = store.presets.allThemes.first(where: { $0.id == theme.id }) else { return .result() }
		found.apply(to: &store.state)
		await store.deliver()
		return .result()
	}
}

struct StartBoardTimerIntent: AppIntent {
	static let title: LocalizedStringResource = "Start Board Timer"

	@Parameter(title: "Minutes", default: 25, inclusiveRange: (1, 180)) var minutes: Int

	static var parameterSummary: some ParameterSummary { Summary("Start a \(\.$minutes) minute board timer") }

	@MainActor func perform() async throws -> some IntentResult {
		let store = BoardStore.shared
		store.startTimer(minutes: minutes)
		await store.deliver()
		return .result()
	}
}

struct PauseBoardTimerIntent: AppIntent {
	static let title: LocalizedStringResource = "Pause Board Timer"

	@MainActor func perform() async throws -> some IntentResult {
		let store = BoardStore.shared
		store.pauseTimer()
		await store.deliver()
		return .result()
	}
}

struct ResetBoardTimerIntent: AppIntent {
	static let title: LocalizedStringResource = "Reset Board Timer"

	@MainActor func perform() async throws -> some IntentResult {
		let store = BoardStore.shared
		store.resetTimer()
		await store.deliver()
		return .result()
	}
}

struct BoardShortcuts: AppShortcutsProvider {
	static var appShortcuts: [AppShortcut] {
		AppShortcut(intent: SetBoardPowerIntent(), phrases: ["Turn \(.applicationName) on or off"],
		            shortTitle: "Power", systemImageName: "power")
		AppShortcut(intent: StartBoardTimerIntent(), phrases: ["Start a timer on \(.applicationName)"],
		            shortTitle: "Start Timer", systemImageName: "timer")
		AppShortcut(intent: SetBoardModeIntent(), phrases: ["Change \(.applicationName) mode"],
		            shortTitle: "Mode", systemImageName: "square.grid.3x3.fill")
		AppShortcut(intent: SetBoardJumpingIntent(), phrases: ["Turn \(.applicationName) jumping on or off"],
		            shortTitle: "Jumping", systemImageName: "arrow.up.and.down.square.fill")
	}
}
