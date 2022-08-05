import Fluent
import FluentPostgresDriver
import Leaf
import Vapor

// configures your application
public func configure(_ app: Application) throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    let dbConfig = Config.instance.database
    app.databases.use(.postgres(
        hostname: dbConfig.host,
        port: dbConfig.port,
        username: dbConfig.username,
        password: dbConfig.password,
        database: dbConfig.database
    ), as: .psql)

    app.migrations.add(CreateUser())

    app.views.use(.leaf)

    // register routes
    try routes(app)
}
