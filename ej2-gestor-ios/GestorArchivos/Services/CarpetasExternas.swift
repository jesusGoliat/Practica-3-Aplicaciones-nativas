import Foundation

/// Carpeta fuera del sandbox autorizada por el usuario (iCloud Drive u otra
/// ubicación de la app Archivos).
struct CarpetaExterna: Codable, Identifiable, Hashable {
    let id: UUID
    var nombre: String
    var marcador: Data
}

/// Conserva el permiso a carpetas externas con marcadores de seguridad
/// (security-scoped bookmarks) guardados en UserDefaults.
final class CarpetasExternas: ObservableObject {
    private let clave = "carpetasExternas"
    @Published private(set) var carpetas: [CarpetaExterna] = [] {
        didSet { UserDefaults.standard.set(try? JSONEncoder().encode(carpetas), forKey: clave) }
    }

    init() {
        if let datos = UserDefaults.standard.data(forKey: clave),
           let lista = try? JSONDecoder().decode([CarpetaExterna].self, from: datos) {
            carpetas = lista
        }
    }

    /// Guarda el marcador de una carpeta elegida con UIDocumentPicker.
    func agregar(_ url: URL) throws {
        let acceso = url.startAccessingSecurityScopedResource()
        defer { if acceso { url.stopAccessingSecurityScopedResource() } }
        let marcador = try url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
        carpetas.removeAll { $0.nombre == url.lastPathComponent }
        carpetas.append(CarpetaExterna(id: UUID(), nombre: url.lastPathComponent, marcador: marcador))
    }

    func quitar(_ carpeta: CarpetaExterna) {
        carpetas.removeAll { $0.id == carpeta.id }
    }

    /// Resuelve el marcador y abre el acceso. Quien llama debe cerrar el
    /// acceso con `stopAccessingSecurityScopedResource()` al terminar.
    func abrir(_ carpeta: CarpetaExterna) throws -> URL {
        var obsoleto = false
        let url = try URL(resolvingBookmarkData: carpeta.marcador, options: [], relativeTo: nil, bookmarkDataIsStale: &obsoleto)
        guard url.startAccessingSecurityScopedResource() else { throw ErrorArchivo.sinAcceso }
        if obsoleto, let nuevo = try? url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil),
           let i = carpetas.firstIndex(of: carpeta) {
            carpetas[i].marcador = nuevo
        }
        return url
    }
}
