import AppKit
import BoardKit

/// Tells the board when you've left the desk: no keyboard or mouse for as long as the presence setting says.
final class PresenceMonitor {
	private var task: Task<Void, Never>?

	func start(store: BoardStore) {
		guard task == nil else { return }
		task = Task {
			while !Task.isCancelled {
				let presence = store.state.automation.presence
				let idle = CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: CGEventType(rawValue: ~0)!)
				let away = presence.isEnabled && idle >= Double(presence.idleMinutes) * 60
				if store.state.isAway != away { store.state.isAway = away }
				try? await Task.sleep(for: .seconds(3))
			}
		}
	}
}
