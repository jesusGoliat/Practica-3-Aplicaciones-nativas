import Foundation
import SwiftUI

/// Archivo abierto recientemente.
struct Reciente: Codable, Hashable {
    /// Ruta relativa al contenedor de la app (ver `Preferencias.relativa`).
    let ruta: String
    let fecha: Date
}

/// Preferencias de la sesión, favoritos y recientes, persistidos en
/// UserDefaults. Las rutas se guardan relativas al contenedor de la app
/// porque la ruta absoluta cambia al reinstalar en el simulador.
final class Preferencias: ObservableObject {
    private enum Clave {
        static let tema = "tema"
        static let apariencia = "apariencia"
        static let orden = "orden"
        static let ascendente = "ascendente"
        static let ultimaCarpeta = "ultimaCarpeta"
        static let favoritos = "favoritos"
        static let recientes = "recientes"
    }

    private let defaults: UserDefaults
    static let maxRecientes = 25

    @Published var tema: TemaApp { didSet { defaults.set(tema.rawValue, forKey: Clave.tema) } }
    @Published var apariencia: Apariencia { didSet { defaults.set(apariencia.rawValue, forKey: Clave.apariencia) } }
    @Published var orden: CriterioOrden { didSet { defaults.set(orden.rawValue, forKey: Clave.orden) } }
    @Published var ascendente: Bool { didSet { defaults.set(ascendente, forKey: Clave.ascendente) } }
    @Published private(set) var favoritos: [String] { didSet { defaults.set(favoritos, forKey: Clave.favoritos) } }
    @Published private(set) var recientes: [Reciente] {
        didSet { defaults.set(try? JSONEncoder().encode(recientes), forKey: Clave.recientes) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        tema = TemaApp(rawValue: defaults.string(forKey: Clave.tema) ?? "") ?? .guinda
        apariencia = Apariencia(rawValue: defaults.string(forKey: Clave.apariencia) ?? "") ?? .sistema
        orden = CriterioOrden(rawValue: defaults.string(forKey: Clave.orden) ?? "") ?? .nombre
        ascendente = defaults.object(forKey: Clave.ascendente) as? Bool ?? true
        favoritos = defaults.stringArray(forKey: Clave.favoritos) ?? []
        if let datos = defaults.data(forKey: Clave.recientes),
           let lista = try? JSONDecoder().decode([Reciente].self, from: datos) {
            recientes = lista
        } else {
            recientes = []
        }
    }

    // MARK: Última carpeta visitada

    var ultimaCarpeta: URL? {
        get { defaults.string(forKey: Clave.ultimaCarpeta).map(Self.absoluta) }
        set { defaults.set(newValue.map(Self.relativa), forKey: Clave.ultimaCarpeta) }
    }

    // MARK: Favoritos

    func esFavorito(_ url: URL) -> Bool { favoritos.contains(Self.relativa(url)) }

    func alternarFavorito(_ url: URL) {
        let rel = Self.relativa(url)
        if let i = favoritos.firstIndex(of: rel) { favoritos.remove(at: i) } else { favoritos.append(rel) }
    }

    var urlsFavoritas: [URL] { favoritos.map(Self.absoluta) }

    // MARK: Recientes

    func registrarReciente(_ url: URL) {
        let rel = Self.relativa(url)
        recientes.removeAll { $0.ruta == rel }
        recientes.insert(Reciente(ruta: rel, fecha: Date()), at: 0)
        if recientes.count > Self.maxRecientes { recientes.removeLast(recientes.count - Self.maxRecientes) }
    }

    func limpiarRecientes() { recientes = [] }

    /// Mantiene favoritos y recientes cuando un archivo se renombra, mueve o elimina.
    func rutaCambio(de anterior: URL, a nueva: URL?) {
        let viejo = Self.relativa(anterior)
        let nuevo = nueva.map(Self.relativa)
        favoritos = favoritos.compactMap { ruta in
            guard ruta == viejo || ruta.hasPrefix(viejo + "/") else { return ruta }
            return nuevo.map { $0 + String(ruta.dropFirst(viejo.count)) }
        }
        recientes = recientes.compactMap { r in
            guard r.ruta == viejo || r.ruta.hasPrefix(viejo + "/") else { return r }
            return nuevo.map { Reciente(ruta: $0 + String(r.ruta.dropFirst(viejo.count)), fecha: r.fecha) }
        }
    }

    // MARK: Rutas relativas al contenedor

    private static var hogar: String {
        URL(fileURLWithPath: NSHomeDirectory()).resolvingSymlinksInPath().path
    }

    static func relativa(_ url: URL) -> String {
        let ruta = url.resolvingSymlinksInPath().path
        return ruta.hasPrefix(hogar) ? String(ruta.dropFirst(hogar.count)) : ruta
    }

    static func absoluta(_ relativa: String) -> URL {
        relativa.hasPrefix(hogar) ? URL(fileURLWithPath: relativa) : URL(fileURLWithPath: hogar + relativa)
    }
}
