import Fluent
import Vapor
import NIOFoundationCompat

enum AuthError: Error {
    case notVerifiedInServer
    case badUUID
}

class AuthController: RouteCollection {
    private func _authURL() -> String {
        let oauth = Config.instance.oauth
        var builder = URLComponents(string: "https://discord.com/oauth2/authorize")!
        builder.queryItems = [
            URLQueryItem(name: "client_id", value: oauth.clientID),
            URLQueryItem(name: "redirect_uri", value: oauth.redirectURL),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "identify guilds.members.read"),
            URLQueryItem(name: "prompt", value: "none"),
        ]
        return builder.url!.absoluteString
    }
    lazy var authURL: String = _authURL()

    func boot(routes: RoutesBuilder) throws {
        routes.group("auth") { builder in
            builder.get("callback", use: callback)
            builder.get("login", use: goToDiscord)
        }
    }
    func goToDiscord(req: Request) async throws -> Response {
        if req.auth.has(User.self) {
            return req.redirect(to: "/")
        }

        return req.redirect(to: authURL)
    }
    private func getToken(_ req: Request, for code: String) async throws -> String {
        let oauth = Config.instance.oauth
        struct TokenData: Content {
            let client_id: String
            let client_secret: String
            let grant_type: String = "authorization_code"
            let code: String
            let redirect_uri: String
        }
        struct AccessToken: Content {
            let access_token: String
        }

        let data = TokenData(
            client_id: oauth.clientID,
            client_secret: oauth.clientSecret,
            code: code,
            redirect_uri: Config.instance.oauth.redirectURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        )

        let resp = try await req.client.post("https://discord.com/api/v10/oauth2/token") { rq in
            try rq.content.encode(data, as: .urlEncodedForm)
            rq.headers.contentType = .urlEncodedForm
        }
        let token = try resp.content.decode(AccessToken.self)

        return token.access_token
    }
    private func getDiscordNick(_ req: Request, token: String) async throws -> String {
        struct DiscordUser: Content {
            let username: String
        }
        struct GuildMember: Content {
            let user: DiscordUser
            let nick: String?
            let roles: [String]
        }
        let discord = Config.instance.discord

        let resp = try await req.client.get("https://discord.com/api/v10/users/@me/guilds/\(discord.serverID)/member") { rq in
            rq.headers.add(name: .authorization, value: "Bearer \(token)")
        }
        let member = try resp.content.decode(GuildMember.self)

        guard member.roles.contains(discord.roleID) else {
            throw AuthError.notVerifiedInServer
        }

        return member.nick ?? member.user.username
    }
    func usernameToUUID(_ req: Request, username: String) async throws -> UUID {
        struct Body: Content {
            let name: String
            let id: String
        }
        let resp = try await req.client.get("https://api.mojang.com/users/profiles/minecraft/\(username)")
        let body = try resp.content.decode(Body.self)
        let badID = body.id
        let chunkOne = String(badID.prefix(8))
        let chunkTwo = String(badID.dropFirst(8).prefix(4))
        let chunkThree = String(badID.dropFirst(12).prefix(4))
        let chunkFour = String(badID.dropFirst(16).prefix(4))
        let chunkFive = String(badID.suffix(12))
        let cleaned: String = [chunkOne, chunkTwo, chunkThree, chunkFour, chunkFive].joined(separator: "-")
        guard let uuid = UUID(uuidString: cleaned) else {
            throw AuthError.badUUID
        }
        return uuid
    }
    func callback(req: Request) async throws -> Response {
        if req.auth.has(User.self) {
            return req.redirect(to: "/")
        }

        let token = try await getToken(req, for: req.query.get(String.self, at: "code"))
        let nick = try await getDiscordNick(req, token: token)
        let uuid = try await usernameToUUID(req, username: nick)
        let user: User

        if let us = try await User.query(on: req.db).filter(\.$id == uuid).first() {
            user = us
        } else {
            user = User(id: uuid)
            try await user.create(on: req.db)
        }

        req.auth.login(user)

        return req.redirect(to: "/")
    }
}
