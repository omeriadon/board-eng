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

    board.get("state") { _ in
        await store.state
    }

    board.put("state") { req async throws -> BoardState in
        let input = try req.content.decode(BoardState.self).validated()
        return await store.update(input)
    }

    // Stub: the board connects here (one socket; a new connection replaces the old one).
    // It gets the current state on connect and on every PUT. Incoming messages are ignored for now.
    board.webSocket("socket") { _, ws in
        await store.connect(ws)
        ws.onClose.whenComplete { _ in
            Task { await store.disconnect(ws) }
        }
    }
}
