import Foundation

@MainActor
@Observable
final class AppRouter {
    enum Route: Equatable { case srs }
    private(set) var pendingRoute: Route?

    @discardableResult
    func handle(_ url: URL) -> Bool {
        // Старые виджеты и сохранённые ссылки продолжают открывать приложение.
        guard let scheme = url.scheme?.lowercased(),
              scheme == "leksipo" || scheme == "englishwords",
              url.host?.lowercased() == "srs",
              url.path.isEmpty || url.path == "/",
              url.user == nil, url.password == nil, url.port == nil,
              url.query == nil, url.fragment == nil else { return false }
        pendingRoute = .srs
        return true
    }

    func consume(_ route: Route) {
        if pendingRoute == route { pendingRoute = nil }
    }
}
