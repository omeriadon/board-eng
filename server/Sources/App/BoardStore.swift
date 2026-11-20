import Vapor

/// The one board's state, plus the one board socket. There are no accounts, devices or IDs.
actor BoardStore {
    private(set) var state: BoardState = .default
    private var socket: WebSocket?

    func update(_ newState: BoardState) -> BoardState {
        state = newState
        if let socket { send(.state(newState), to: socket) }
        return newState
    }

    /// Makes `ws` the board socket (closing any previous one) and sends it the current state.
    /// Nothing here suspends, so a concurrent `update` can't interleave and reorder messages.
    func connect(_ ws: WebSocket) {
        if let old = socket, old !== ws { old.close(promise: nil) }
        socket = ws
        send(.state(state), to: ws)
    }

    /// Called when a socket closes; ignored if it has already been replaced.
    func disconnect(_ ws: WebSocket) {
        if socket === ws { socket = nil }
    }

    var isBoardConnected: Bool { socket != nil }

    private func send(_ message: SocketMessage, to ws: WebSocket) {
        guard !ws.isClosed,
              let data = try? JSONEncoder().encode(message),
              let text = String(data: data, encoding: .utf8) else { return }
        ws.send(text, promise: nil)
    }
}
