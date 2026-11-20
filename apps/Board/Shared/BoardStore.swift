import BoardKit
import Observation
import SwiftUI

/// The app's single source of truth for the board. Persists locally for now;
/// later this syncs with the board (BLE / local Wi-Fi) and the server.
@Observable
final class BoardStore {
	var state: BoardState { didSet { save() } }
	let geometry = BoardGeometry.standard

	private static let key = "boardState"

	init() {
		if let data = UserDefaults.standard.data(forKey: Self.key),
		   let saved = try? JSONDecoder().decode(BoardState.self, from: data) {
			state = saved
		} else {
			state = BoardState()
		}
	}

	private func save() {
		if let data = try? JSONEncoder().encode(state) {
			UserDefaults.standard.set(data, forKey: Self.key)
		}
	}
}
