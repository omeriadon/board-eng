import Foundation

/// Wi-Fi: a WebSocket to the server, which relays to the board (and to your other devices). It works from anywhere,
/// not only within Bluetooth range. Each frame is one `BoardMessage`.
@MainActor
final class WebSocketTransport: BoardTransport {
	let kind = LinkKind.wifi
	var onReceive: (([UInt8]) -> Void)?
	var onConnectionChange: (() -> Void)?
	private(set) var isConnected = false {
		didSet { if oldValue != isConnected { onConnectionChange?() } }
	}
	/// A short description of the last problem, for the Device screen.
	private(set) var lastError: String?

	private var task: URLSessionWebSocketTask?
	private var url: URL?
	private var token = ""
	private var enabled = false
	private var generation = 0
	private var attempts = 0

	func configure(url: URL?, token: String, enabled: Bool) {
		let changed = url != self.url || token != self.token || enabled != self.enabled
		self.url = url
		self.token = token
		self.enabled = enabled
		guard changed else { return }
		disconnect()
		if enabled, url != nil { connect() }
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
		// A pong proves the upgrade worked, so the badge never claims a link that isn't there.
		task.sendPing { [weak self] error in
			Task { @MainActor in
				guard let self, mine == self.generation else { return }
				if let error {
					self.lastError = error.localizedDescription
					self.scheduleReconnect()
				} else {
					self.lastError = nil
					self.attempts = 0
					self.isConnected = true
					self.listen(task, mine)
					self.keepAlive(task, mine)
				}
			}
		}
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
