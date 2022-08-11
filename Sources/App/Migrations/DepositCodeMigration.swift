import Fluent

struct DepositCodeMigration: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("deposit_codes")
            .id()
            .field("code", .string, .required)
            .unique(on: "code", name: "deposit_code_unique")
            .field("issuer_id", .uuid, .references("users", "id"), .required)
            .field("iron_amount", .int, .required)
            .field("diamond_amount", .int, .required)
            .field("redeemed", .bool, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("deposit_codes")
            .delete()
    }
}
