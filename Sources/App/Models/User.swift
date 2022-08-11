import Fluent
import Vapor

enum Role: String, Codable {
    case owner
    case admin
    case teller
    case member
}

final class User: Model, ModelSessionAuthenticatable {
    static let schema = "users"

    /// conveniently the same as Mojang UUID
    @ID(key: .id)
    var id: UUID?

    /// what role this user has on the site.
    @Enum(key: "role")
    var role: Role

    /// what is this user's iron balance?
    @Field(key: "iron_balance")
    var ironBalance: Int

    /// what is this user's diamond balance?
    @Field(key: "diamond_balance")
    var diamondBalance: Int

    init() { }

    init(id: UUID, role: Role, iron: Int, diamonds: Int) {
        self.id = id
        self.role = role
        self.ironBalance = iron
        self.diamondBalance = diamonds
    }
}
