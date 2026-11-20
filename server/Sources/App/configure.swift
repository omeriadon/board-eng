import Vapor

public func configure(_ app: Application) async throws {
    try await configure(app, config: .fromEnvironment())
}

func configure(_ app: Application, config: BoardConfig) async throws {
    if config.apiToken == nil {
        if app.environment.isRelease {
            throw Abort(.internalServerError, reason: "BOARD_API_TOKEN must be set in production.")
        }
        app.logger.warning("BOARD_API_TOKEN is not set: /v1 routes and the board socket are unauthenticated.")
    }

    app.http.server.configuration.hostname = config.hostname
    app.http.server.configuration.port = config.port

    try routes(app, config: config, store: BoardStore(dataDirectory: config.dataDirectory, logger: app.logger))
}
