import Fluent

struct CreateUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("users")
            .id()
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("users").delete()
    }
}
