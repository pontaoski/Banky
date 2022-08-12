import Fluent
import Vapor

struct EnsureRoleMiddleware: AsyncMiddleware {
    let role: Role

    init(role: Role) {
        self.role = role
    }

    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        guard let user = request.auth.get(User.self), user.role >= self.role else {
            throw Abort(.unauthorized)
        }
        return try await next.respond(to: request)
    }
}

class TellerController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let prot = routes.grouped(User.redirectMiddleware(path: "/auth/login"))
                         .grouped(EnsureRoleMiddleware(role: .teller))

        prot.group("account") { routes in
            routes.get(":who", "adjust-balance", use: adjustBalance)
            routes.post(":who", "adjust-balance", use: doAdjustBalance)
        }
    }
    struct AdjustBalance: Codable {
        struct Form: Codable {
            var ironAdjustment: Int = 0
            var diamondAdjustment: Int = 0
        }

        var form: Form = Form()
        var errors: [String] = []
    }
    func adjustBalance(request: Request) async throws -> View {
        return try await request.view.render("accounts/adjust_balance", AdjustBalance())
    }
    func doAdjustBalance(request: Request) async throws -> Response {
        let form = try request.content.decode(AdjustBalance.Form.self)
        let who = request.parameters.get("who")!
        let uuid = try await usernameUUIDCache.uuid(for: who)

        guard let user = try await User.query(on: request.db).filter(\.$id == uuid).first() else {
            return try await request.formErrors(form: "accounts/adjust_balance", context: AdjustBalance(form: form, errors: ["That user doesn't have an account yet..."]))
        }

        user.ironBalance += form.ironAdjustment
        user.diamondBalance += form.diamondAdjustment

        try await user.save(on: request.db)

        return request.redirect(to: "/account/\(who)?adjust_success=yes")
    }
}