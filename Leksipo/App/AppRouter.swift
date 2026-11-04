import Foundation

@MainActor
@Observable
final class AppRouter {
    enum Route: Equatable {
        case srs
        case groupImport(URL)
    }
    private(set) var pendingRoute: Route?

    @discardableResult
    func handle(_ url: URL) -> Bool {
        if url.isFileURL, url.pathExtension.lowercased() == "json",
           !url.hasDirectoryPath, url.query == nil, url.fragment == nil,
           url.user == nil, url.password == nil, url.port == nil,
           url.host == nil || url.host == "" || url.host == "localhost" {
            pendingRoute = .groupImport(url)
            return true
        }
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
