import Foundation
import Observation

/// Wi-Fi: a WebSocket to the server, which relays to the board (and to your other devices). It works from anywhere,
/// not only within Bluetooth range. Each frame is one `BoardMessage`.
@MainActor
@Observable
final class WebSocketTransport: BoardTransport {
	let kind = LinkKind.wifi
	@ObservationIgnored var onReceive: (([UInt8]) -> Void)?
	@ObservationIgnored var onConnectionChange: (() -> Void)?
	private(set) var isConnected = false {
		didSet { if oldValue != isConnected { onConnectionChange?() } }
	}
	/// A short description of the last problem, for the Device screen.
	private(set) var lastError: String?

	@ObservationIgnored private var task: URLSessionWebSocketTask?
	@ObservationIgnored private var url: URL?
	@ObservationIgnored private var token = ""
	@ObservationIgnored private var enabled = false
	@ObservationIgnored private var generation = 0
	@ObservationIgnored private var attempts = 0

	func configure(url: URL?, token: String, enabled: Bool) {
		let changed = url != self.url || token != self.token || enabled != self.enabled
		self.url = url
		self.token = token
		self.enabled = enabled
		guard changed else { return }
		disconnect()
		guard enabled else { lastError = nil; return }
		if url == nil { lastError = "Enter the server address"; return }
		if token.isEmpty { lastError = "Enter the password"; return }
		lastError = nil
		connect()
	}

	func send(_ bytes: [UInt8]) {
		guard isConnected, let task else { return }
		task.send(.data(Data(bytes))) { _ in }
	}

	private func connect() {
		guard enabled, let url else { return }
		generation += 1
		let mine = generation
		var request = URLRequest(url: url)
		request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		let task = URLSession.shared.webSocketTask(with: request)
		self.task = task
		task.resume()
		// The server speaks first (the time, then the state), so the first message received proves the upgrade worked,
		// and the badge never claims a link that isn't there. (A ping isn't used for this: the proxy doesn't answer it.)
		listen(task, mine)
	}

	private func disconnect() {
		generation += 1
		task?.cancel(with: .goingAway, reason: nil)
		task = nil
		isConnected = false
	}

	private func listen(_ task: URLSessionWebSocketTask, _ mine: Int) {
		task.receive { [weak self] result in
			Task { @MainActor in
				guard let self, mine == self.generation else { return }
				switch result {
					case let .success(message):
						if !self.isConnected {
							self.lastError = nil
							self.attempts = 0
							self.isConnected = true
							self.keepAlive(task, mine)
						}
						if case let .data(data) = message { self.onReceive?([UInt8](data)) }
						self.listen(task, mine)
					case let .failure(error):
						self.lastError = error.localizedDescription
						self.isConnected = false
						self.scheduleReconnect()
				}
			}
		}
	}

	/// Proxies drop quiet sockets, so ping every 20 seconds.
	private func keepAlive(_ task: URLSessionWebSocketTask, _ mine: Int) {
		Task { [weak self] in
			while !Task.isCancelled {
				try? await Task.sleep(for: .seconds(20))
				guard let self, mine == generation else { return }
				task.sendPing { [weak self] error in
					guard error != nil else { return }
					Task { @MainActor in
						guard let self, mine == self.generation else { return }
						self.isConnected = false
						self.scheduleReconnect()
					}
				}
			}
		}
	}

	private func scheduleReconnect() {
		generation += 1
		let mine = generation
		task?.cancel(with: .goingAway, reason: nil)
		task = nil
		attempts += 1
		let delay = min(30, 1 << min(attempts, 5))
		Task { [weak self] in
			try? await Task.sleep(for: .seconds(delay))
			guard let self, mine == generation, enabled else { return }
			connect()
		}
	}
}
