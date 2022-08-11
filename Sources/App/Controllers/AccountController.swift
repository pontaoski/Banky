import Fluent
import Vapor

fileprivate struct AccountData: Codable {
    let user: User
    let mcUserID: String
    let depositSuccessful: Bool?
}

fileprivate struct NotCreatedAccountData: Codable {
    let display: String
    let uuidString: String
}

extension Vapor.HTTPMediaType {
    static var turboStream: Vapor.HTTPMediaType = .init(type: "text", subType: "vnd.turbo-stream.html")
}

extension Request {
    var isTurboStream: Bool {
        self.headers.accept.contains(where: { $0.mediaType == .turboStream && $0.mediaType != .html })
    }
    func formErrors<T: Codable>(form: String, context: T) async throws -> Response {
        if self.isTurboStream {
            return try await TurboStreamView(self.view.render("turbo_form_errors", context))
                .encodeResponse(for: self)
                .get()
        } else {
            return try await self.view.render(form, context)
                .encodeResponse(for: self)
                .get()
        }
    }
}

public struct TurboStreamView: ResponseEncodable {
    public var data: ByteBuffer

    public init(_ view: View) {
        self.data = view.data
    }

    public func encodeResponse(for request: Request) -> EventLoopFuture<Response> {
        let response = Response()
        response.status = .unprocessableEntity
        response.headers.contentType = .turboStream
        response.body = .init(buffer: self.data, byteBufferAllocator: request.byteBufferAllocator)
        return request.eventLoop.makeSucceededFuture(response)
    }
}


class AccountController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let prot = routes.grouped(User.redirectMiddleware(path: "/auth/login"))
        prot.group("account") { routes in
            routes.get("@me", use: me)
            routes.get(":who", use: otherUser)
            routes.get("@me", "deposit-code", use: useDepositCode)
            routes.post("@me", "deposit-code", use: postDepositCode)
        }
    }
    func me(request: Request) async throws -> View {
        let user = try request.auth.require(User.self)
        return try await request.view.render("accounts/account",
            AccountData(
                user: user,
                mcUserID: user.id!.uuidString.lowercased(),
                depositSuccessful: (try? request.query.get(String.self, at: "funds_added")).map { $0 == "yes" }
            )
        )
    }
    func otherUser(request: Request) async throws -> View {
        let who = request.parameters.get("who")!
        let uuid: UUID
        do {
            uuid = try await AuthController.usernameToUUID(request, username: who)
        } catch {
            return try await request.view.render("bad_account", who)
        }
        guard let user = try await User.query(on: request.db).filter(\.$id == uuid).first() else {
            return try await request.view.render("account_not_made_yet", NotCreatedAccountData(display: who, uuidString: uuid.uuidString.lowercased()))
        }
        return try await request.view.render("accounts/account", AccountData(user: user, mcUserID: user.id!.uuidString.lowercased(), depositSuccessful: nil))
    }
    struct DepositCodeForm: Codable {
        var depositCode: String = ""
        var errors: [String] = []
    }
    func useDepositCode(request: Request) async throws -> View {
        return try await request.view.render("accounts/use_deposit_code", DepositCodeForm())
    }
    func postDepositCode(request: Request) async throws -> Response {
        struct Form: Content {
            let code: String
        }
        let form = try request.content.decode(Form.self)
        let user: User = try request.auth.require()
        let context = DepositCodeForm(depositCode: form.code)

        guard let depositCode = try await DepositCode.query(on: request.db)
            .filter(\.$code == form.code.lowercased().replacingOccurrences(of: "-", with: ""))
            .first() else {

            var ctx = context
            ctx.errors = ["The deposit code \(form.code) doesn't exist."]

            return try await request.formErrors(form: "accounts/use_deposit_code", context: ctx)
        }

        guard !depositCode.redeemed else {
            var ctx = context
            ctx.errors = ["The deposit code \(form.code) was already redeemed."]

            return try await request.formErrors(form: "accounts/use_deposit_code", context: ctx)
        }

        try await request.db.transaction { db in
            user.ironBalance += depositCode.ironAmount
            user.diamondBalance += depositCode.diamondAmount
            try await user.save(on: db)

            depositCode.redeemed = true
            try await depositCode.save(on: db)
        }

        return request.redirect(to: "/account/@me?funds_added=yes")
    }
}