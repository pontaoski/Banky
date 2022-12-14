import Vapor
import Foundation

struct AppData: Codable {
    var user: UserWrapper?
    var mcUserID: String?

    init(from req: Request) async throws {
        if let user = req.auth.get(User.self) {
            self.user = try await UserWrapper(user: user)
            self.mcUserID = user.id?.uuidString.lowercased()
        }
    }
}

struct NoData: Codable { }

struct WrappedRenderer: ViewRenderer {
    let inner: ViewRenderer

    struct Wrapper: ViewRenderer {
        let inner: ViewRenderer
        let request: Request

        struct Merged<T>: Encodable where T: Encodable {
            var data: T
            var app: AppData
        }

        func `for`(_ request: Request) -> ViewRenderer {
            return self
        }

        func render<E>(_ name: String, _ context: E) -> EventLoopFuture<View> where E : Encodable {
            let promise = self.request.eventLoop.makePromise(of: View.self)
            promise.completeWithTask {
                let merged = Merged(
                    data: context,
                    app: try await AppData(from: self.request)
                )

                return try await self.inner.render(name, merged)
            }
            return promise.futureResult
        }
    }

    func `for`(_ request: Request) -> ViewRenderer {
        return Wrapper(inner: inner.for(request), request: request)
    }

    func render<E>(_ name: String, _ context: E) -> EventLoopFuture<View> where E : Encodable {
        return inner.render(name, context)
    }
}
