import Fluent
import Vapor

final class User: Model, ModelSessionAuthenticatable {
    static let schema = "users"

    /// conveniently the same as Mojang UUID
    @ID(key: .id)
    var id: UUID?

    init() { }

    init(id: UUID) {
        self.id = id
    }
}
