@testable import App
import BoardKit
import Foundation
import Logging
import Testing
import Vapor
import VaporTesting

private let token = "test-token"

private var authHeaders: HTTPHeaders {
    var headers = HTTPHeaders()
    headers.bearerAuthorization = BearerAuthorization(token: token)
    return headers
}

private func withApp(
    token: String? = token,
    dataDirectory: String? = nil,
    _ test: (Application) async throws -> Void
) async throws {
    let app = try await Application.make(.testing)
    do {
        try await configure(app, config: BoardConfig(apiToken: token, dataDirectory: dataDirectory))
        try await test(app)
    } catch {
        try? await app.asyncShutdown()
        throw error
    }
    try await app.asyncShutdown()
}

/// A real server on a random port, for the tests that need sockets.
private func withLiveApp(
    dataDirectory: String? = nil,
    _ test: (Application, Int) async throws -> Void
) async throws {
    let app = try await Application.make(Environment(name: "testing", arguments: ["vapor"]))
    do {
        try await configure(app, config: BoardConfig(apiToken: token, dataDirectory: dataDirectory))
        app.http.server.configuration.hostname = "127.0.0.1"
        app.http.server.configuration.port = 0
        try await app.startup()
        let port = try #require(app.http.server.shared.localAddress?.port)
        try await test(app, port)
    } catch {
        try? await app.asyncShutdown()
        throw error
    }
    try await app.asyncShutdown()
}

private func temporaryDirectory() -> String {
    FileManager.default.temporaryDirectory.appendingPathComponent("board-server-tests-\(UUID().uuidString)").path
}

/// A client of the socket: collects every binary frame, decoded, in order.
private final class TestSocket: @unchecked Sendable {
    private let ws: WebSocket
    private var frames: AsyncStream<[UInt8]>.AsyncIterator
    private let closed: AsyncStream<Void>

    private init(ws: WebSocket, frames: AsyncStream<[UInt8]>, closed: AsyncStream<Void>) {
        self.ws = ws
        self.frames = frames.makeAsyncIterator()
        self.closed = closed
    }

    static func connect(app: Application, port: Int, query: String = "", headers: HTTPHeaders? = nil) async throws -> TestSocket {
        let (opened, openedContinuation) = AsyncStream<TestSocket>.makeStream()
        let future: EventLoopFuture<Void> = WebSocket.connect(
            to: "ws://127.0.0.1:\(port)/v1/board/socket\(query)",
            headers: headers ?? authHeaders,
            on: app.eventLoopGroup
        ) { ws in
            let (frames, framesContinuation) = AsyncStream<[UInt8]>.makeStream()
            let (closed, closedContinuation) = AsyncStream<Void>.makeStream()
            ws.onBinary { _, buffer in framesContinuation.yield(Array(buffer.readableBytesView)) }
            ws.onClose.whenComplete { _ in
                framesContinuation.finish()
                closedContinuation.yield()
                closedContinuation.finish()
            }
            openedContinuation.yield(TestSocket(ws: ws, frames: frames, closed: closed))
            openedContinuation.finish()
        }
        future.whenFailure { _ in openedContinuation.finish() }
        var iterator = opened.makeAsyncIterator()
        return try #require(await iterator.next())
    }

    /// The next frame, or nil once the socket has closed.
    func next() async -> BoardMessage? {
        guard let bytes = await frames.next() else { return nil }
        return BoardMessage(decoding: bytes)
    }

    func send(_ message: BoardMessage) async throws { try await ws.send(message.encoded()) }
    func send(raw bytes: [UInt8]) async throws { try await ws.send(bytes) }

    var isClosed: Bool { ws.isClosed }

    func close() async { try? await ws.close() }
}

private func changed(_ mutate: (inout BoardState) -> Void) -> BoardState {
    var state = BoardState()
    mutate(&state)
    return state
}

/// What a client sees of a message: colours travel as 8-bit pixels, so a state comes back rounded to those.
private func wire(_ message: BoardMessage) -> BoardMessage {
    BoardMessage(decoding: message.encoded()) ?? message
}

private func revision(_ counter: UInt32, origin: UInt8 = 1) -> Revision {
    Revision(counter: counter, origin: origin)
}

private func testArtwork() -> Artwork {
    Artwork(id: 7, side: 2, pixels: [Pixel(r: 1, g: 2, b: 3), Pixel(r: 4, g: 5, b: 6), Pixel(r: 7, g: 8, b: 9), Pixel(r: 10, g: 11, b: 12)])
}

private func testStatus() -> BoardStatus {
    var status = BoardStatus()
    status.firmware = 3
    status.uptimeSeconds = 99
    status.temperature = 31.5
    status.ambientLight = 0.25
    status.links = 3
    return status
}

@Suite("Board server", .serialized)
struct AppTests {
    // MARK: HTTP

    @Test("GET /health")
    func health() async throws {
        try await withApp { app in
            let tester = try app.testing()
            try await tester.test(.GET, "health") { res async throws in
                #expect(res.status == .ok)
                #expect(try res.content.decode(HealthResponse.self).status == "ok")
            }
        }
    }

    @Test("GET /time is public and returns UTC by default")
    func time() async throws {
        try await withApp { app in
            let before = Int64(Date().timeIntervalSince1970 * 1000)
            let tester = try app.testing()
            try await tester.test(.GET, "time") { res async throws in
                #expect(res.status == .ok)
                #expect(res.headers.first(name: .cacheControl) == "no-store")
                let body = try res.content.decode(TimeResponse.self)
                #expect(body.utcOffsetSeconds == 0)
                #expect(body.unixMillis >= before)
                #expect(body.unixMillis - before < 5_000)
                #expect(body.iso8601.hasSuffix("Z"))
            }
        }
    }

    @Test("GET /time?tz= returns the zone's offset")
    func timeZone() async throws {
        try await withApp { app in
            let tester = try app.testing()
            try await tester.test(.GET, "time?tz=Australia/Perth") { res async throws in
                #expect(res.status == .ok)
                #expect(try res.content.decode(TimeResponse.self).utcOffsetSeconds == 8 * 3600)
            }
            try await tester.test(.GET, "time?tz=Asia/Kolkata") { res async throws in
                #expect(try res.content.decode(TimeResponse.self).utcOffsetSeconds == 19_800)
            }
        }
    }

    @Test("GET /time with an invalid tz is a 400")
    func timeInvalidZone() async throws {
        try await withApp { app in
            let tester = try app.testing()
            try await tester.test(.GET, "time?tz=Mars/Olympus_Mons") { res async throws in
                #expect(res.status == .badRequest)
            }
            try await tester.test(.GET, "time?tz=") { res async throws in
                #expect(res.status == .badRequest)
            }
        }
    }

    @Test("/v1 routes reject missing or wrong tokens")
    func authRejection() async throws {
        try await withApp { app in
            let tester = try app.testing()
            try await tester.test(.GET, "v1/board/state") { res async throws in
                #expect(res.status == .unauthorized)
            }
            var wrong = HTTPHeaders()
            wrong.bearerAuthorization = BearerAuthorization(token: "nope")
            try await tester.test(.GET, "v1/board/state", headers: wrong) { res async throws in
                #expect(res.status == .unauthorized)
            }
            try await tester.test(.PUT, "v1/board/state", headers: wrong, beforeRequest: { req in
                try req.content.encode(BoardState())
            }) { res async throws in
                #expect(res.status == .unauthorized)
            }
            try await tester.test(.GET, "v1/board/socket") { res async throws in
                #expect(res.status == .unauthorized)
            }
            // Public routes stay public.
            try await tester.test(.GET, "health") { res async throws in
                #expect(res.status == .ok)
            }
        }
    }

    @Test("State PUT/GET round-trip as JSON")
    func stateRoundTrip() async throws {
        try await withApp { app in
            let tester = try app.testing()
            try await tester.test(.GET, "v1/board/state", headers: authHeaders) { res async throws in
                #expect(res.status == .ok)
                #expect(try res.content.decode(BoardState.self) == BoardState())
            }

            let new = changed { $0.isOn = false; $0.brightness = 0.25; $0.mode = .ambient }
            try await tester.test(.PUT, "v1/board/state", headers: authHeaders, beforeRequest: { req in
                try req.content.encode(new)
            }) { res async throws in
                #expect(res.status == .ok)
                #expect(try res.content.decode(BoardState.self) == new)
            }
            try await tester.test(.GET, "v1/board/state", headers: authHeaders) { res async throws in
                #expect(try res.content.decode(BoardState.self) == new)
            }
        }
    }

    @Test("State PUT bounds out-of-range values and rejects malformed bodies")
    func stateBounding() async throws {
        try await withApp { app in
            let tester = try app.testing()
            let wild = changed { $0.brightness = 7 }
            try await tester.test(.PUT, "v1/board/state", headers: authHeaders, beforeRequest: { req in
                try req.content.encode(wild)
            }) { res async throws in
                #expect(res.status == .ok)
                #expect(try res.content.decode(BoardState.self) == wild.bounded())
                #expect(try res.content.decode(BoardState.self).brightness == 1)
            }
            try await tester.test(.PUT, "v1/board/state", headers: authHeaders, beforeRequest: { req in
                req.headers.contentType = .json
                req.body = ByteBuffer(string: ##"{"mode":"disco"}"##)
            }) { res async throws in
                #expect((400 ..< 500).contains(Int(res.status.code)))
            }
            try await tester.test(.GET, "v1/board/state", headers: authHeaders) { res async throws in
                #expect(try res.content.decode(BoardState.self) == wild.bounded())
            }
        }
    }

    // MARK: Socket

    @Test("A connection is sent the time, then the state", .timeLimit(.minutes(1)))
    func socketGreeting() async throws {
        try await withLiveApp { app, port in
            let before = UInt64(Date().timeIntervalSince1970 * 1000)
            let socket = try await TestSocket.connect(app: app, port: port)

            guard case let .time(millis, offset)? = await socket.next() else {
                Issue.record("The first frame wasn't the time")
                return
            }
            #expect(millis >= before)
            #expect(millis - before < 5_000)
            #expect(offset == 0)
            #expect(await socket.next() == wire(.state(.zero, BoardState())))

            await socket.close()
        }
    }

    @Test("?tz= sets the offset in the time message", .timeLimit(.minutes(1)))
    func socketTimeZone() async throws {
        try await withLiveApp { app, port in
            let socket = try await TestSocket.connect(app: app, port: port, query: "?tz=Australia/Perth")
            guard case let .time(_, offset)? = await socket.next() else {
                Issue.record("The first frame wasn't the time")
                return
            }
            #expect(offset == 8 * 3600)
            await socket.close()
        }
    }

    @Test("The socket needs the token", .timeLimit(.minutes(1)))
    func socketAuth() async throws {
        try await withLiveApp { app, port in
            var wrong = HTTPHeaders()
            wrong.bearerAuthorization = BearerAuthorization(token: "nope")
            let (opened, continuation) = AsyncStream<Bool>.makeStream()
            let future: EventLoopFuture<Void> = WebSocket.connect(
                to: "ws://127.0.0.1:\(port)/v1/board/socket", headers: wrong, on: app.eventLoopGroup
            ) { ws in
                continuation.yield(true)
                continuation.finish()
                ws.close(promise: nil)
            }
            future.whenComplete { _ in continuation.finish() }
            var iterator = opened.makeAsyncIterator()
            #expect(await iterator.next() == nil)
        }
    }

    @Test("A state from one client reaches the others, not the sender; duplicates and older ones are dropped", .timeLimit(.minutes(1)))
    func socketRelay() async throws {
        try await withLiveApp { app, port in
            let a = try await TestSocket.connect(app: app, port: port)
            let b = try await TestSocket.connect(app: app, port: port)
            for socket in [a, b] {
                _ = await socket.next() // time
                _ = await socket.next() // state
            }

            let one = changed { $0.brightness = 0.1 }
            let two = changed { $0.brightness = 0.2; $0.mode = .timer }
            try await a.send(.state(revision(1), one))
            try await a.send(.state(revision(2), two))
            try await a.send(.state(revision(2), one)) // the same revision again: a duplicate
            try await a.send(.state(revision(1), one)) // older than what's applied
            try await a.send(.command(.homeAll, argument: 0))

            #expect(await b.next() == wire(.state(revision(1), one)))
            #expect(await b.next() == wire(.state(revision(2), two)))
            #expect(await b.next() == .command(.homeAll, argument: 0))

            // The sender gets none of it back: its next frame is the answer to its own request.
            try await a.send(.requestState)
            #expect(await a.next() == wire(.state(revision(2), two)))
            try await b.send(.command(.reboot, argument: 0))
            #expect(await a.next() == .command(.reboot, argument: 0))

            await a.close()
            await b.close()
        }
    }

    @Test("Artwork and status are relayed and handed to new connections", .timeLimit(.minutes(1)))
    func socketArtworkAndStatus() async throws {
        try await withLiveApp { app, port in
            let a = try await TestSocket.connect(app: app, port: port)
            let b = try await TestSocket.connect(app: app, port: port)
            for socket in [a, b] {
                _ = await socket.next()
                _ = await socket.next()
            }

            try await a.send(.artwork(testArtwork()))
            try await a.send(.status(testStatus()))
            #expect(await b.next() == .artwork(testArtwork()))
            #expect(await b.next() == .status(testStatus()))

            let late = try await TestSocket.connect(app: app, port: port)
            guard case .time? = await late.next() else {
                Issue.record("The first frame wasn't the time")
                return
            }
            #expect(await late.next() == wire(.state(.zero, BoardState())))
            #expect(await late.next() == .artwork(testArtwork()))
            #expect(await late.next() == .status(testStatus()))

            // requestState answers with the state and the artwork.
            try await late.send(.requestState)
            #expect(await late.next() == wire(.state(.zero, BoardState())))
            #expect(await late.next() == .artwork(testArtwork()))

            for socket in [a, b, late] { await socket.close() }
        }
    }

    @Test("A time message from a client is ignored", .timeLimit(.minutes(1)))
    func socketIgnoresClientTime() async throws {
        try await withLiveApp { app, port in
            let a = try await TestSocket.connect(app: app, port: port)
            let b = try await TestSocket.connect(app: app, port: port)
            for socket in [a, b] {
                _ = await socket.next()
                _ = await socket.next()
            }
            try await a.send(.time(unixMillis: 5, utcOffsetSeconds: 5))
            try await a.send(.command(.stopTest, argument: 0))
            #expect(await b.next() == .command(.stopTest, argument: 0))
            await a.close()
            await b.close()
        }
    }

    @Test("Garbage frames are skipped and the socket stays open", .timeLimit(.minutes(1)))
    func socketGarbage() async throws {
        try await withLiveApp { app, port in
            let socket = try await TestSocket.connect(app: app, port: port)
            _ = await socket.next()
            _ = await socket.next()

            try await socket.send(raw: [])
            try await socket.send(raw: [0xFF, 0xFF, 0xFF])
            try await socket.send(raw: [BoardMessage.version, 99]) // unknown message type
            try await socket.send(raw: BoardMessage.requestState.encoded() + [0]) // trailing byte
            try await socket.send(raw: Array(BoardMessage.state(revision(1), BoardState()).encoded().dropLast())) // truncated
            try await socket.send(raw: Array(repeating: 0xAB, count: 4_000))

            try await socket.send(.requestState)
            #expect(await socket.next() == wire(.state(.zero, BoardState())))
            #expect(!socket.isClosed)
            await socket.close()
        }
    }

    @Test("PUT /v1/board/state is sent to every socket as a server revision", .timeLimit(.minutes(1)))
    func putBroadcasts() async throws {
        try await withLiveApp { app, port in
            let a = try await TestSocket.connect(app: app, port: port)
            let b = try await TestSocket.connect(app: app, port: port)
            for socket in [a, b] {
                _ = await socket.next()
                _ = await socket.next()
            }

            let new = changed { $0.brightness = 0.9; $0.mode = .music }
            let response = try await app.client.put(
                URI(string: "http://127.0.0.1:\(port)/v1/board/state"), headers: authHeaders
            ) { try $0.content.encode(new) }
            #expect(response.status == .ok)

            let expected = BoardMessage.state(Revision(counter: 1, origin: BoardStore.origin), new.bounded())
            #expect(await a.next() == wire(expected))
            #expect(await b.next() == wire(expected))

            // A change from a client with a higher counter then replaces it.
            let later = changed { $0.brightness = 0.3 }
            try await a.send(.state(revision(5), later))
            #expect(await b.next() == wire(.state(revision(5), later)))

            await a.close()
            await b.close()
        }
    }

    // MARK: Persistence

    @Test("The state survives a restart, byte for byte")
    func persistence() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(atPath: directory) }
        let logger = Logger(label: "test")

        let first = BoardStore(dataDirectory: directory, logger: logger)
        #expect(await first.current == .state(.zero, BoardState()))
        let new = changed { $0.brightness = 0.4; $0.mode = .timer; $0.isAway = true }
        _ = await first.change(to: new)
        let saved = await first.current
        #expect(saved == .state(Revision(counter: 1, origin: BoardStore.origin), new))

        let file = URL(fileURLWithPath: directory).appendingPathComponent(BoardStore.stateFileName)
        #expect(Array(try Data(contentsOf: file)) == saved.encoded())

        let second = BoardStore(dataDirectory: directory, logger: logger)
        #expect(await second.current == wire(saved))
        // And it carries on from there.
        _ = await second.change(to: BoardState())
        #expect(await second.current == .state(Revision(counter: 2, origin: BoardStore.origin), BoardState()))
    }

    @Test("A missing or corrupt state file starts from the default")
    func persistenceFallback() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(atPath: directory) }
        let logger = Logger(label: "test")

        #expect(await BoardStore(dataDirectory: directory, logger: logger).current == .state(.zero, BoardState()))
        try Data([1, 2, 3]).write(to: URL(fileURLWithPath: directory).appendingPathComponent(BoardStore.stateFileName))
        #expect(await BoardStore(dataDirectory: directory, logger: logger).current == .state(.zero, BoardState()))
    }

    @Test("A state set over the socket is saved, and loaded by the next server", .timeLimit(.minutes(1)))
    func socketStateIsSaved() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(atPath: directory) }
        let new = changed { $0.brightness = 0.77; $0.mode = .ambient }

        try await withLiveApp(dataDirectory: directory) { app, port in
            let socket = try await TestSocket.connect(app: app, port: port)
            _ = await socket.next()
            _ = await socket.next()
            try await socket.send(.state(revision(4, origin: 2), new))
            try await socket.send(.requestState)
            _ = await socket.next()
            await socket.close()
        }

        try await withLiveApp(dataDirectory: directory) { app, port in
            let socket = try await TestSocket.connect(app: app, port: port)
            _ = await socket.next()
            #expect(await socket.next() == wire(.state(revision(4, origin: 2), new)))
            await socket.close()
        }
    }
}
