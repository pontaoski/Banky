import Fluent

final class Product: Model {
    static let schema = "products"

    @ID(key: .id)
    var id: UUID?
}
