import Capacitor

final class ClubAbiertoViewController: CAPBridgeViewController {
    override func router() -> Router {
        return ClubAbiertoRouter()
    }
}

// The website serves these directories as index.html. Capacitor's default
// SPA router otherwise sends extensionless paths to the home screen.
struct ClubAbiertoRouter: Router {
    var basePath: String = ""

    private let directoryRoutes: Set<String> = [
        "/comunidad-formativa/vinculo",
        "/comunidad-formativa/acompanamiento",
        "/comunidad-formativa/integridad",
        "/comunidad-formativa/presentaciones"
    ]

    func route(for path: String) -> String {
        let routePath = path.hasSuffix("/") ? String(path.dropLast()) : path
        if directoryRoutes.contains(routePath) {
            return basePath + routePath + "/index.html"
        }
        var fallback = CapacitorRouter()
        fallback.basePath = basePath
        return fallback.route(for: path.isEmpty ? "/" : path)
    }
}

