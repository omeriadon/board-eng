import Vapor

/// Runtime configuration, read from environment variables.
struct BoardConfig: Sendable {
    /// Shared bearer token for `/v1` routes and the board socket. `nil` disables auth (development only).
    var apiToken: String?
    var hostname: String
    var port: Int
    /// Where the latest state is saved between restarts. `nil` saves nothing (used by tests).
    var dataDirectory: String?

    init(apiToken: String?, hostname: String = "127.0.0.1", port: Int = 8080, dataDirectory: String? = nil) {
        // An empty token is treated as "not set".
        self.apiToken = (apiToken?.isEmpty == false) ? apiToken : nil
        self.hostname = hostname
        self.port = port
        self.dataDirectory = dataDirectory
    }

    /// `BOARD_API_TOKEN`, `HOST` (default 127.0.0.1), `PORT` (default 8080) and `BOARD_DATA_DIR` (default `./data`;
    /// the Docker image sets it to `/data`).
    static func fromEnvironment() -> BoardConfig {
        BoardConfig(
            apiToken: Environment.get("BOARD_API_TOKEN"),
            hostname: Environment.get("HOST") ?? "127.0.0.1",
            port: Environment.get("PORT").flatMap(Int.init) ?? 8080,
            dataDirectory: Environment.get("BOARD_DATA_DIR").flatMap { $0.isEmpty ? nil : $0 } ?? "./data"
        )
    }
}
