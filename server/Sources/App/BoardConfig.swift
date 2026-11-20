import Vapor

/// Runtime configuration, read from environment variables.
struct BoardConfig: Sendable {
    /// Shared bearer token for `/v1` routes and the board socket. `nil` disables auth (development only).
    var apiToken: String?
    var hostname: String
    var port: Int

    init(apiToken: String?, hostname: String = "127.0.0.1", port: Int = 8080) {
        // An empty token is treated as "not set".
        self.apiToken = (apiToken?.isEmpty == false) ? apiToken : nil
        self.hostname = hostname
        self.port = port
    }

    /// `BOARD_API_TOKEN`, `HOST` (default 127.0.0.1) and `PORT` (default 8080).
    static func fromEnvironment() -> BoardConfig {
        BoardConfig(
            apiToken: Environment.get("BOARD_API_TOKEN"),
            hostname: Environment.get("HOST") ?? "127.0.0.1",
            port: Environment.get("PORT").flatMap(Int.init) ?? 8080
        )
    }
}
