import Fluent

struct UserRolesAndBalance: AsyncMigration {
    func prepare(on database: Database) async throws {
        let roleEnum = try await database.enum("roles")
            .case("owner")
            .case("admin")
            .case("teller")
            .case("member")
            .create()

        try await database.schema("users")
            .field("role", roleEnum, .required)
            .field("iron_balance", .int, .required)
            .field("diamond_balance", .int, .required)
            .update()
    }

    func revert(on database: Database) async throws {
        try await database.enum("roles").delete()
        try await database.schema("users")
            .deleteField("role")
            .deleteField("iron_balance")
            .deleteField("diamond_balance")
            .update()
    }
}
