import Vapor

/// Requires `Authorization: Bearer <BOARD_API_TOKEN>`. Passes everything through when no token is configured.
struct BoardAuthMiddleware: AsyncMiddleware {
    let token: String?

    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        if let token {
            guard let provided = request.headers.bearerAuthorization?.token,
                  Self.constantTimeEquals(provided, token) else {
                throw Abort(.unauthorized, headers: ["WWW-Authenticate": "Bearer"], reason: "Missing or invalid bearer token.")
            }
        }
        return try await next.respond(to: request)
    }

    static func constantTimeEquals(_ a: String, _ b: String) -> Bool {
        let x = Array(a.utf8), y = Array(b.utf8)
        var diff = x.count ^ y.count
        for i in 0..<max(x.count, y.count) {
            diff |= Int(i < x.count ? x[i] : 0) ^ Int(i < y.count ? y[i] : 0)
        }
        return diff == 0
    }
}
