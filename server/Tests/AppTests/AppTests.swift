@testable import App
import Foundation
import Testing
import Vapor
import VaporTesting

private let token = "test-token"

private func withApp(
    token: String? = token,
    _ test: (Application) async throws -> Void
) async throws {
    let app = try await Application.make(.testing)
    do {
        try await configure(app, config: BoardConfig(apiToken: token))
        try await test(app)
    } catch {
        try? await app.asyncShutdown()
        throw error
    }
    try await app.asyncShutdown()
}

private final class ClientSocket: @unchecked Sendable {
    var ws: WebSocket?
}

private var authHeaders: HTTPHeaders {
    var headers = HTTPHeaders()
    headers.bearerAuthorization = BearerAuthorization(token: token)
    return headers
}

@Suite("Board server", .serialized)
struct AppTests {
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
                try req.content.encode(BoardState.default)
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

    @Test("State PUT/GET round-trip")
    func stateRoundTrip() async throws {
        try await withApp { app in
            let tester = try app.testing()
            try await tester.test(.GET, "v1/board/state", headers: authHeaders) { res async throws in
                #expect(res.status == .ok)
                #expect(try res.content.decode(BoardState.self) == .default)
            }

            let newState = BoardState(power: false, brightness: 0.25, mode: .ambient, palette: ["#ff8800", "#00AAFF"])
            let expected = BoardState(power: false, brightness: 0.25, mode: .ambient, palette: ["#FF8800", "#00AAFF"])
            try await tester.test(.PUT, "v1/board/state", headers: authHeaders, beforeRequest: { req in
                try req.content.encode(newState)
            }) { res async throws in
                #expect(res.status == .ok)
                #expect(try res.content.decode(BoardState.self) == expected)
            }
            try await tester.test(.GET, "v1/board/state", headers: authHeaders) { res async throws in
                #expect(try res.content.decode(BoardState.self) == expected)
            }
        }
    }

    @Test("State PUT validates input")
    func stateValidation() async throws {
        try await withApp { app in
            let tester = try app.testing()
            let bad: [BoardState] = [
                BoardState(power: true, brightness: 1.5, mode: .dither, palette: ["#000000"]),
                BoardState(power: true, brightness: -0.1, mode: .dither, palette: ["#000000"]),
                BoardState(power: true, brightness: 0.5, mode: .dither, palette: []),
                BoardState(power: true, brightness: 0.5, mode: .dither, palette: ["red"]),
                BoardState(power: true, brightness: 0.5, mode: .dither, palette: ["#12345G"]),
                BoardState(power: true, brightness: 0.5, mode: .dither, palette: Array(repeating: "#000000", count: 9)),
            ]
            for state in bad {
                try await tester.test(.PUT, "v1/board/state", headers: authHeaders, beforeRequest: { req in
                    try req.content.encode(state)
                }) { res async throws in
                    #expect(res.status == .badRequest)
                }
            }
            // Unknown mode / malformed body is a client error, and the stored state is untouched.
            try await tester.test(.PUT, "v1/board/state", headers: authHeaders, beforeRequest: { req in
                req.headers.contentType = .json
                req.body = ByteBuffer(string: ##"{"power":true,"brightness":0.5,"mode":"disco","palette":["#000000"]}"##)
            }) { res async throws in
                #expect((400..<500).contains(Int(res.status.code)))
            }
            try await tester.test(.GET, "v1/board/state", headers: authHeaders) { res async throws in
                #expect(try res.content.decode(BoardState.self) == .default)
            }
        }
    }

    @Test("Socket sends state on connect and broadcasts PUTs", .timeLimit(.minutes(1)))
    func socketBroadcast() async throws {
        let app = try await Application.make(Environment(name: "testing", arguments: ["vapor"]))
        do {
            try await configure(app, config: BoardConfig(apiToken: token))
            app.http.server.configuration.hostname = "127.0.0.1"
            app.http.server.configuration.port = 0
            try await app.startup()
            let port = try #require(app.http.server.shared.localAddress?.port)

            let (stream, continuation) = AsyncStream<String>.makeStream()
            let client = ClientSocket()
            let connection = Task {
                try await WebSocket.connect(
                    to: "ws://127.0.0.1:\(port)/v1/board/socket",
                    headers: authHeaders,
                    on: app.eventLoopGroup
                ) { ws in
                    client.ws = ws
                    ws.onText { _, text in continuation.yield(text) }
                    ws.onClose.whenComplete { _ in continuation.finish() }
                }.get()
            }
            var messages = stream.makeAsyncIterator()

            let first = try #require(await messages.next())
            let initial = try JSONDecoder().decode(SocketMessage.self, from: Data(first.utf8))
            #expect(initial.type == "state")
            #expect(initial.state == .default)

            let update = BoardState(power: true, brightness: 0.9, mode: .music, palette: ["#112233"])
            let response = try await app.client.put(
                URI(string: "http://127.0.0.1:\(port)/v1/board/state"),
                headers: authHeaders
            ) { try $0.content.encode(update) }
            #expect(response.status == .ok)

            let second = try #require(await messages.next())
            let pushed = try JSONDecoder().decode(SocketMessage.self, from: Data(second.utf8))
            #expect(pushed.state == update)

            try await client.ws?.close()
            connection.cancel()
        } catch {
            try? await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }
}
