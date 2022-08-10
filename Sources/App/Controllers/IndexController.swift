import Vapor

struct IndexController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: index)
    }
    func index(req: Request) async throws -> View {
        return try await req.view.render("index", NoData())
    }
}
