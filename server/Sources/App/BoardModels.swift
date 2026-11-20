import BoardKit
import Vapor

// The board's state, artwork and wire messages all come from the shared BoardKit package.
// The only types here are the JSON bodies of the public /health and /time routes.

/// Lets Vapor read and write BoardKit's `Codable` state as JSON for `GET`/`PUT /v1/board/state`.
extension BoardState: @retroactive Content {}

struct HealthResponse: Content {
    var status: String
}

struct TimeResponse: Content {
    var unixMillis: Int64
    var iso8601: String
    var utcOffsetSeconds: Int
}
