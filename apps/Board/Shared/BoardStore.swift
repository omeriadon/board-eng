import BoardKit
import Foundation
import Observation

/// The app's single source of truth for the board. Every local change is stamped and sent on every link;
/// every message that arrives is merged by revision, so a change made on another device shows up here too.
@Observable
final class BoardStore {
	/// One store for the whole process, so Shortcuts (App Intents) change the same board the UI shows.
	static let shared = BoardStore()

	var state: BoardState {
		didSet {
			guard oldValue != state else { return }
			save()
			if !applyingRemote { link.send(sync.change(to: state)) }
		}
	}

	/// The current album art (Mac only; sent to the board once per track).
	var artwork: Artwork? {
		didSet { if artwork != oldValue { link.send(.artwork(artwork ?? Artwork(id: 0, side: 0, pixels: []))) } }
	}

	let geometry = BoardGeometry.standard
	let link = BoardLink()
	let presets = PresetStore()
	let connection = ConnectionSettings()

	let webSocket = WebSocketTransport()
	let bluetooth = BluetoothTransport()

	@ObservationIgnored private var sync: StateSync
	@ObservationIgnored private var applyingRemote = false

	private static let key = "boardState"
	private static let originKey = "boardOrigin"

	init() {
		let saved = UserDefaults.standard.data(forKey: Self.key).flatMap { try? JSONDecoder().decode(BoardState.self, from: $0) }
		var initial = saved?.bounded() ?? BoardState()
		// "Away" is a live fact about the desk, not something to restore from last time.
		initial.isAway = false
		#if DEBUG
			// Launch with `-debugMode 2` to start in a given mode (for checking each mode's look).
			if UserDefaults.standard.string(forKey: "debugMode") != nil, let mode = BoardMode(rawValue: UInt8(UserDefaults.standard.integer(forKey: "debugMode"))) { initial.mode = mode }
		#endif
		state = initial

		// Each install has its own id, so two devices never stamp a change identically.
		var origin = UInt8(UserDefaults.standard.integer(forKey: Self.originKey))
		if origin == 0 {
			origin = UInt8.random(in: 1 ... 254)
			UserDefaults.standard.set(Int(origin), forKey: Self.originKey)
		}
		sync = StateSync(origin: origin, state: initial)

		link.add(bluetooth)
		link.add(webSocket)
		link.onMessage = { [weak self] message in self?.receive(message) }
		link.onLinkUp = { [weak self] in self?.linkCameUp() }
		applyConnectionSettings()
	}

	/// Call after the server address, password or link switches change.
	func applyConnectionSettings() {
		webSocket.configure(url: connection.socketURL, token: connection.token, enabled: connection.useServer)
		bluetooth.configure(enabled: connection.useBluetooth)
	}

	/// A link just connected: offer what we have (a stale board or server takes it if it's newer) and ask for theirs.
	private func linkCameUp() {
		link.send(sync.current)
		link.send(.requestState)
		if let artwork { link.send(.artwork(artwork)) }
	}

	private func receive(_ message: BoardMessage) {
		switch message {
			case .state:
				if sync.receive(message) {
					applyingRemote = true
					state = sync.state
					applyingRemote = false
				}
			case .requestState:
				link.send(sync.current)
			case .status, .time, .artwork, .command:
				break
		}
	}

	func send(_ command: BoardCommand, argument: UInt8 = 0) {
		link.send(.command(command, argument: argument))
	}

	private func save() {
		if let data = try? JSONEncoder().encode(state) { UserDefaults.standard.set(data, forKey: Self.key) }
	}

	// MARK: Timer

	static var nowMillis: UInt64 { UInt64(Date().timeIntervalSince1970 * 1000) }

	func startTimer() {
		state.mode = .timer
		state.timer.start(now: Self.nowMillis)
	}

	func startTimer(minutes: Int) {
		state.timer.reset()
		state.timer.durationSeconds = max(1, minutes) * 60
		startTimer()
	}

	func pauseTimer() { state.timer.pause(now: Self.nowMillis) }
	func resetTimer() { state.timer.reset() }
}

/// The user's own presets and themes, saved on this device. The built-in ones live in BoardKit.
@Observable
final class PresetStore {
	private(set) var custom: [Preset] {
		didSet { Self.save(custom, key: "customPresets") }
	}
	private(set) var customThemes: [ColorTheme] {
		didSet { Self.save(customThemes, key: "customThemes") }
	}

	var all: [Preset] { custom + Preset.builtIn }
	var allThemes: [ColorTheme] { customThemes + ColorTheme.builtIn }
	var suggestedName: String { "My Preset \(custom.count + 1)" }
	var suggestedThemeName: String { "My Theme \(customThemes.count + 1)" }

	init() {
		custom = Self.load("customPresets") ?? []
		customThemes = Self.load("customThemes") ?? []
	}

	func add(name: String, settings: DitherSettings) {
		let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
		custom.insert(Preset(id: UUID().uuidString, name: trimmed.isEmpty ? suggestedName : trimmed, settings: settings, isCustom: true), at: 0)
	}

	func delete(_ preset: Preset) { custom.removeAll { $0.id == preset.id } }

	func addTheme(name: String, colors: [RGB]) {
		let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
		customThemes.insert(ColorTheme(id: UUID().uuidString, name: trimmed.isEmpty ? suggestedThemeName : trimmed, colors: colors, isCustom: true), at: 0)
	}

	func delete(_ theme: ColorTheme) { customThemes.removeAll { $0.id == theme.id } }

	private static func save<T: Encodable>(_ value: T, key: String) {
		if let data = try? JSONEncoder().encode(value) { UserDefaults.standard.set(data, forKey: key) }
	}

	private static func load<T: Decodable>(_ key: String) -> T? {
		UserDefaults.standard.data(forKey: key).flatMap { try? JSONDecoder().decode(T.self, from: $0) }
	}
}
