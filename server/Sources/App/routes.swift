import BoardKit
import Vapor

func routes(_ app: Application, config: BoardConfig, store: BoardStore) throws {
    // MARK: Public

    // The Pico asks for this on startup and after any power loss. Keep it tiny and uncached.
    app.get("time") { req async throws -> Response in
        let now = Date()
        var offset = 0
        if let zoneName = req.query[String.self, at: "tz"] {
            guard let zone = TimeZone(identifier: zoneName) else {
                throw Abort(.badRequest, reason: "Unknown time zone '\(zoneName)'.")
            }
            offset = zone.secondsFromGMT(for: now)
        }
        let body = TimeResponse(
            unixMillis: Int64((now.timeIntervalSince1970 * 1000).rounded(.down)),
            iso8601: now.formatted(Date.ISO8601FormatStyle()),
            utcOffsetSeconds: offset
        )
        let response = Response()
        try response.content.encode(body, as: .json)
        response.headers.replaceOrAdd(name: .cacheControl, value: "no-store")
        return response
    }

    app.get("health") { _ async in
        HealthResponse(status: "ok")
    }

    // MARK: Authenticated (/v1)

    let board = app.grouped("v1", "board").grouped(BoardAuthMiddleware(token: config.apiToken))

    // For Shortcuts, curl and debugging. The apps and the board use the socket.
    board.get("state") { _ in
        await store.state
    }

    // JSON in, the bounded state out. Sent to every socket, as a change made by the server itself.
    board.put("state") { req async throws -> BoardState in
        await store.change(to: try req.content.decode(BoardState.self))
    }

    // Binary frames, each one `BoardMessage.encoded()`. The apps and the board all connect here.
    // `?tz=Australia/Perth` sets the offset in the time message sent on connect (UTC if absent or unknown).
    board.webSocket("socket") { req, ws in
        var offset: Int32 = 0
        if let zoneName = req.query[String.self, at: "tz"], let zone = TimeZone(identifier: zoneName) {
            offset = Int32(truncatingIfNeeded: zone.secondsFromGMT(for: Date()))
        }

        // This closure runs on the socket's event loop, which is where its callbacks have to be set.
        // Frames are handled in the order they arrive, one at a time, once the socket has been added.
        let (frames, continuation) = AsyncStream<[UInt8]>.makeStream()
        ws.onBinary { _, buffer in
            continuation.yield(Array(buffer.readableBytesView))
        }
        ws.onClose.whenComplete { _ in continuation.finish() }
        ws.pingInterval = .seconds(20)

        Task {
            await store.connect(ws, utcOffsetSeconds: offset)
            for await bytes in frames {
                await store.receive(bytes, from: ws)
            }
            // The stream ends when the socket closes. Removing it here, after `connect` has run, can't race it.
            await store.disconnect(ws)
        }
    }
}
