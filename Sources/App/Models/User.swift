import Fluent
import Vapor

enum Role: String, Codable, Comparable {
    private static func minimum(_ lhs: Self, _ rhs: Self) -> Self {
        switch (lhs, rhs) {
        case (.member, _), (_, .member): return .member
        case (.teller, _), (_, .teller): return .teller
        case (.admin, _), (_, .admin): return .admin
        case (.owner, _), (_, .owner): return .owner
        }
    }
    static func <(lhs: Role, rhs: Role) -> Bool {
        return lhs != rhs && lhs == Self.minimum(lhs, rhs)
    }

    case owner
    case admin
    case teller
    case member
}

final class UserWrapper: Codable {
    var user: User

    var id: UUID? { get { user.id } }
    var role: Role? { get { user.role }}
    var ironBalance: Int? { get { user.ironBalance }}
    var diamondBalance: Int? { get { user.diamondBalance }}
    var isOwner: Bool { get { user.role >= .owner } }
    var isAdmin: Bool { get { user.role >= .admin } }
    var isTeller: Bool { get { user.role >= .teller } }
    var isMember: Bool { get { user.role >= .member } }
    var username: String

    enum CodingKeys: CodingKey {
        case user
        case id
        case role
        case ironBalance
        case diamondBalance
        case isOwner
        case isAdmin
        case isTeller
        case isMember
        case username
    }

    func encode(to encoder: Encoder) throws {
        var cont = encoder.container(keyedBy: CodingKeys.self)
        try cont.encode(user, forKey: .user)
        try cont.encode(id, forKey: .id)
        try cont.encode(role, forKey: .role)
        try cont.encode(ironBalance, forKey: .ironBalance)
        try cont.encode(diamondBalance, forKey: .diamondBalance)
        try cont.encode(isOwner, forKey: .isOwner)
        try cont.encode(isAdmin, forKey: .isAdmin)
        try cont.encode(isTeller, forKey: .isTeller)
        try cont.encode(isMember, forKey: .isMember)
        try cont.encode(username, forKey: .username)
    }

    init(from decoder: Decoder) throws {
        let cont = try decoder.container(keyedBy: CodingKeys.self)
        self.user = try cont.decode(User.self, forKey: .user)
        self.username = try cont.decode(String.self, forKey: .username)
    }

    init(user: User) async throws {
        self.user = user
        self.username = try await usernameUUIDCache.username(for: user.id!)
    }
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
