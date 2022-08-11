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
    func renderTurbo<T: Codable>(form: String, context: T) async throws -> Response {
        return try await TurboStreamView(self.view.render(form, context))
            .encodeResponse(for: self)
            .get()
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

func randomString(length: Int) -> String {
    let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0..<length).map{ _ in letters.randomElement()! })
}

func randomDepositCode() -> String {
    return randomString(length: 3) + "-" + randomString(length: 3) + "-" + randomString(length: 4)
}

extension String {
    var depositDBCode: String {
        self.lowercased().replacingOccurrences(of: "-", with: "")
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
            routes.get("@me", "create-deposit-code", use: createDepositCode)
            routes.post("@me", "create-deposit-code", use: postCreateDepositCode)
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
            .filter(\.$code == form.code.depositDBCode)
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
    struct CreateDepositCodeForm: Codable {
        var diamondAmount: Int = 0
        var ironAmount: Int = 0
        var errors: [String] = []
    }
    func createDepositCode(request: Request) async throws -> View {
        return try await request.view.render("accounts/create_deposit_code", CreateDepositCodeForm())
    }
    func postCreateDepositCode(request: Request) async throws -> Response {
        struct Form: Codable {
            let diamondAmount: Int
            let ironAmount: Int
        }
        let form = try request.content.decode(Form.self)
        let user: User = try request.auth.require()
        var errors: [String] = []

        if user.diamondBalance < form.diamondAmount {
            errors.append("You only have \(user.diamondBalance)d in your account, but you're trying to create a deposit code for \(form.diamondAmount)d.")
        }
        if user.ironBalance < form.ironAmount {
            errors.append("You only have \(user.ironBalance)i in your account, but you're trying to create a deposit code for \(form.ironAmount)i.")
        }
        if form.diamondAmount == 0 && form.ironAmount == 0 {
            errors.append("You can't create a deposit code without any funds!")
        }
        guard errors.count == 0 else {
            return try await request.formErrors(
                form: "accounts/create_deposit_code",
                context:
                    CreateDepositCodeForm(diamondAmount: form.diamondAmount, ironAmount: form.ironAmount, errors: errors)
                )
        }

        return try await request.db.transaction { db in
            user.diamondBalance -= form.diamondAmount
            user.ironBalance -= form.ironAmount

            try await user.save(on: db)

            let userCode = randomDepositCode()
            let depositCode = DepositCode(code: userCode.depositDBCode, issuer: user, ironAmount: form.ironAmount, diamondAmount: form.diamondAmount)

            try await depositCode.create(on: db)

            if request.isTurboStream {
                struct Code: Codable {
                    let code: String
                }
                return try await request.renderTurbo(form: "accounts/turbo_deposit_code_success", context: Code(code: userCode))
            } else {
                return request.redirect(to: "/accounts/@me/deposit-codes")
            }
        }
    }
}