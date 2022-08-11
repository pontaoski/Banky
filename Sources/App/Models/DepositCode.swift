import Fluent
import Vapor

final class DepositCode: Model {
    static let schema = "deposit_codes"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "code")
    var code: String

    @Parent(key: "issuer_id")
    var issuer: User

    @Field(key: "iron_amount")
    var ironAmount: Int

    @Field(key: "diamond_amount")
    var diamondAmount: Int

    @Field(key: "redeemed")
    var redeemed: Bool

    init() { }

    init(code: String, issuer: User, ironAmount: Int, diamondAmount: Int) {
        self.code = code
        self.$issuer.id = issuer.id!
        self.ironAmount = ironAmount
        self.diamondAmount = diamondAmount
        self.redeemed = false
    }
}
