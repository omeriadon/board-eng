import Vapor

// TODO: replace these local DTOs with the shared `BoardKit` protocol types once that package lands.

enum BoardMode: String, Codable, Sendable, CaseIterable {
    case dither, ambient, music, timer
}

/// The state of the board as stored and relayed by the server.
struct BoardState: Content, Equatable {
    static let maxPaletteColors = 8

    var power: Bool
    /// 0...1
    var brightness: Double
    var mode: BoardMode
    /// `#RRGGBB` strings, 1...8 entries.
    var palette: [String]

    static let `default` = BoardState(
        power: true,
        brightness: 0.5,
        mode: .dither,
        palette: ["#000000", "#FFFFFF"]
    )

    /// Returns a normalised copy (palette upper-cased) or throws `400 Bad Request`.
    func validated() throws -> BoardState {
        guard brightness.isFinite, (0.0...1.0).contains(brightness) else {
            throw Abort(.badRequest, reason: "brightness must be between 0 and 1.")
        }
        guard (1...Self.maxPaletteColors).contains(palette.count) else {
            throw Abort(.badRequest, reason: "palette must contain 1 to \(Self.maxPaletteColors) colours.")
        }
        var copy = self
        copy.palette = try palette.map { color in
            let digits = color.dropFirst()
            guard color.hasPrefix("#"), digits.count == 6, digits.allSatisfy(\.isHexDigit) else {
                throw Abort(.badRequest, reason: "Invalid palette colour '\(color)'; expected #RRGGBB.")
            }
            return color.uppercased()
        }
        return copy
    }
}

struct HealthResponse: Content {
    var status: String
}

struct TimeResponse: Content {
    var unixMillis: Int64
    var iso8601: String
    var utcOffsetSeconds: Int
}

/// Message sent over the board socket.
struct SocketMessage: Codable, Sendable {
    var type: String
    var state: BoardState

    static func state(_ state: BoardState) -> SocketMessage {
        SocketMessage(type: "state", state: state)
    }
}
