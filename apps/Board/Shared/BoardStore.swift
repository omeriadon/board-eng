import BoardKit
import Foundation
import Observation

/// The app's single source of truth for the board. Every local change is stamped and sent on every link;
/// every message that arrives is merged by revision, so a change made on another device shows up here too.
@Observable
final class BoardStore {
	var state: BoardState {
		didSet {
			guard oldValue != state else { return }
			save()
			if !applyingRemote { link.send(sync.change(to: state)) }
		}
	}

	let geometry = BoardGeometry.standard
	let link = BoardLink()
	let presets = PresetStore()

	@ObservationIgnored private var sync: StateSync
	@ObservationIgnored private var applyingRemote = false

	private static let key = "boardState"
	private static let originKey = "boardOrigin"

	init() {
		let saved = UserDefaults.standard.data(forKey: Self.key).flatMap { try? JSONDecoder().decode(BoardState.self, from: $0) }
		let initial = saved?.bounded() ?? BoardState()
		state = initial

		// Each install has its own id, so two devices never stamp a change identically.
		var origin = UInt8(UserDefaults.standard.integer(forKey: Self.originKey))
		if origin == 0 {
			origin = UInt8.random(in: 1 ... 254)
			UserDefaults.standard.set(Int(origin), forKey: Self.originKey)
		}
		sync = StateSync(origin: origin, state: initial)

		link.onMessage = { [weak self] message in self?.receive(message) }
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
			case .status, .time:
				break
		}
	}

	private func save() {
		if let data = try? JSONEncoder().encode(state) { UserDefaults.standard.set(data, forKey: Self.key) }
	}
}

/// The user's own presets, saved on this device. The built-in ones live in BoardKit.
@Observable
final class PresetStore {
	private(set) var custom: [Preset] {
		didSet {
			if let data = try? JSONEncoder().encode(custom) { UserDefaults.standard.set(data, forKey: Self.key) }
		}
	}

	private static let key = "customPresets"

	var all: [Preset] { custom + Preset.builtIn }
	var suggestedName: String { "My Preset \(custom.count + 1)" }

	init() {
		custom = UserDefaults.standard.data(forKey: Self.key).flatMap { try? JSONDecoder().decode([Preset].self, from: $0) } ?? []
	}

	func add(name: String, settings: DitherSettings) {
		let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
		custom.insert(Preset(id: UUID().uuidString, name: trimmed.isEmpty ? suggestedName : trimmed, settings: settings, isCustom: true), at: 0)
	}

	func delete(_ preset: Preset) {
		custom.removeAll { $0.id == preset.id }
	}
}
