import BoardKit
import Foundation
import Logging
import Vapor

/// The one board's state, plus every connected socket. There are no accounts, devices or ids: the apps and the
/// board itself all connect to the same endpoint and are just clients, and the server relays between them.
///
/// Nothing in here suspends, so a message can't be reordered or interleaved with another one while it is handled.
actor BoardStore {
    private var sync: StateSync
    private(set) var artwork: Artwork?
    private(set) var status: BoardStatus?
    private var sockets: [ObjectIdentifier: WebSocket] = [:]

    private let stateFile: URL?
    private let logger: Logger

    /// The server's own id in revisions. Apps and the board use small numbers, so a tie always goes to them.
    static let origin: UInt8 = 255
    static let stateFileName = "state.bin"

    /// `dataDirectory` is where the latest state is kept between restarts; nil keeps nothing on disk.
    init(dataDirectory: String?, logger: Logger) {
        self.logger = logger
        var sync = StateSync(origin: 255)
        var file: URL?
        if let dataDirectory {
            let directory = URL(fileURLWithPath: dataDirectory, isDirectory: true)
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                file = directory.appendingPathComponent("state.bin")
            } catch {
                logger.error("Can't create the data directory \(directory.path), so the state won't be saved: \(error)")
            }
        }
        if let file, let bytes = try? Data(contentsOf: file) {
            if let message = BoardMessage(decoding: Array(bytes)), sync.receive(message) {
                logger.info("Loaded the saved board state (revision \(sync.revision.counter)).")
            } else {
                logger.warning("Ignoring an unreadable saved state at \(file.path).")
            }
        }
        self.sync = sync
        self.stateFile = file
    }

    // MARK: State

    /// The state and its revision, as the message that carries both.
    var current: BoardMessage { sync.current }
    var state: BoardState { sync.state }
    var connectionCount: Int { sockets.count }

    /// A change made here (the `PUT` route): applied, saved, and sent to every socket.
    func change(to new: BoardState) -> BoardState {
        let message = sync.change(to: new)
        persist()
        broadcast(message, except: nil)
        return sync.state
    }

    // MARK: Sockets

    /// Adds `ws` and sends it what it needs to catch up: the time, the state, then the artwork and status if known.
    func connect(_ ws: WebSocket, utcOffsetSeconds: Int32) {
        sockets[ObjectIdentifier(ws)] = ws
        send(.time(unixMillis: Self.nowMillis(), utcOffsetSeconds: utcOffsetSeconds), to: ws)
        sendSnapshot(to: ws)
    }

    func disconnect(_ ws: WebSocket) {
        sockets[ObjectIdentifier(ws)] = nil
    }

    /// One frame from `ws`. Frames that aren't a valid `BoardMessage` are dropped.
    func receive(_ bytes: [UInt8], from ws: WebSocket) {
        guard let message = BoardMessage(decoding: bytes) else {
            logger.debug("Dropped an undecodable \(bytes.count)-byte frame.")
            return
        }
        switch message {
            case .state:
                if sync.receive(message) {
                    persist()
                    broadcast(message, except: ws)
                }
            case .requestState:
                sendSnapshot(to: ws, includingStatus: false)
            case let .artwork(art):
                artwork = art
                broadcast(message, except: ws)
            case let .status(s):
                status = s
                broadcast(message, except: ws)
            case .command:
                broadcast(message, except: ws)
            case .time:
                break // The server is the clock; a client's time is ignored.
        }
    }

    // MARK: Sending

    private func sendSnapshot(to ws: WebSocket, includingStatus: Bool = true) {
        send(sync.current, to: ws)
        if let artwork { send(.artwork(artwork), to: ws) }
        if includingStatus, let status { send(.status(status), to: ws) }
    }

    private func broadcast(_ message: BoardMessage, except origin: WebSocket?) {
        let bytes = message.encoded()
        for (id, ws) in sockets where id != origin.map(ObjectIdentifier.init) {
            send(bytes, to: ws)
        }
    }

    private func send(_ message: BoardMessage, to ws: WebSocket) {
        send(message.encoded(), to: ws)
    }

    private func send(_ bytes: [UInt8], to ws: WebSocket) {
        guard !ws.isClosed else { return }
        ws.send(bytes, promise: nil)
    }

    // MARK: Persistence

    /// The newest applied state, as the same bytes that travel on the wire. Written whole, then moved into place.
    private func persist() {
        guard let stateFile else { return }
        do {
            try Data(sync.current.encoded()).write(to: stateFile, options: .atomic)
        } catch {
            logger.error("Couldn't save the board state: \(error)")
        }
    }

    private static func nowMillis() -> UInt64 {
        UInt64((Date().timeIntervalSince1970 * 1000).rounded(.down))
    }
}
