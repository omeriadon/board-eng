import BoardKit
import Observation

/// A way to reach the board. The phone and Mac don't care which one is up: a change goes out on every link that's
/// connected, as the same bytes, and the board (or server) drops the copy it has already seen.
enum LinkKind: String, CaseIterable {
	case bluetooth, wifi

	var title: String { self == .bluetooth ? "Bluetooth" : "Wi-Fi" }
}

@MainActor
protocol BoardTransport: AnyObject {
	var kind: LinkKind { get }
	var isConnected: Bool { get }
	/// Called with each complete message the transport receives.
	var onReceive: (([UInt8]) -> Void)? { get set }
	func send(_ bytes: [UInt8])
}

/// Fans messages out to every connected transport and funnels what comes back into one stream.
@MainActor
@Observable
final class BoardLink {
	private(set) var transports: [any BoardTransport] = []
	/// The board's last report: temperature, light, firmware.
	private(set) var status: BoardStatus?

	@ObservationIgnored var onMessage: ((BoardMessage) -> Void)?
	@ObservationIgnored private var pending: BoardMessage?
	@ObservationIgnored private var flushTask: Task<Void, Never>?

	/// How often a burst of slider changes goes out at most, so dragging stays smooth over Bluetooth.
	private static let minimumInterval: Duration = .milliseconds(33)

	func add(_ transport: any BoardTransport) {
		transport.onReceive = { [weak self] bytes in
			guard let message = BoardMessage(decoding: bytes) else { return }
			self?.receive(message)
		}
		transports.append(transport)
	}

	var connected: [LinkKind] { LinkKind.allCases.filter { kind in transports.contains { $0.kind == kind && $0.isConnected } } }

	var summary: String {
		let up = connected
		return up.isEmpty ? "Not connected" : up.map(\.title).joined(separator: " + ")
	}

	/// State changes are coalesced: only the newest of a burst is sent, since each message carries the whole state.
	func send(_ message: BoardMessage) {
		guard case .state = message else { transmit(message); return }
		pending = message
		guard flushTask == nil else { return }
		flushTask = Task { [weak self] in
			// First change goes straight out; later ones in the burst wait for the next slot.
			self?.flush()
			try? await Task.sleep(for: Self.minimumInterval)
			guard let self else { return }
			flushTask = nil
			if pending != nil { send(pending!) }
		}
	}

	private func flush() {
		guard let message = pending else { return }
		pending = nil
		transmit(message)
	}

	private func transmit(_ message: BoardMessage) {
		let bytes = message.encoded()
		for transport in transports where transport.isConnected { transport.send(bytes) }
	}

	private func receive(_ message: BoardMessage) {
		if case let .status(s) = message { status = s }
		onMessage?(message)
	}
}
