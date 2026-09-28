import CoreData
import CoreLocation
import UIKit

enum ErrorAlmacen: LocalizedError {
    case imagenInvalida
    case tipoNoSoportado(String)

    var errorDescription: String? {
        switch self {
        case .imagenInvalida: return "No se pudo leer la imagen: el archivo está dañado o no es compatible."
        case .tipoNoSoportado(let ext): return "El tipo de archivo «.\(ext)» no se puede importar."
        }
    }
}

/// Guarda, edita, importa y elimina capturas: archivo en disco + registro en
/// Core Data + miniatura. Todo local, sin Internet.
final class Almacen: ObservableObject {
    static let compartido = Almacen()

    private let fm = FileManager.default
    private let persistencia: Persistencia
    private let cacheMiniaturas = NSCache<NSString, UIImage>()

    /// Documents/Capturas: visible en la app Archivos (UIFileSharingEnabled).
    let raiz: URL

    init(persistencia: Persistencia = .compartida) {
        self.persistencia = persistencia
        raiz = fm.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Capturas", isDirectory: true)
        for sub in ["fotos", "audios", "miniaturas"] {
            try? fm.createDirectory(at: raiz.appendingPathComponent(sub), withIntermediateDirectories: true)
        }
        cacheMiniaturas.countLimit = 200
    }

    var contexto: NSManagedObjectContext { persistencia.contexto }

    func url(de captura: Captura) -> URL { raiz.appendingPathComponent(captura.archivo ?? "") }

    /// Ruta para la siguiente grabación de audio.
    func urlNuevaGrabacion() -> URL {
        raiz.appendingPathComponent("audios/\(Self.nombreNuevo()).m4a")
    }

    // MARK: Guardar

    @discardableResult
    func guardarFoto(_ imagen: UIImage, filtro: FiltroFoto, album: Album?, ubicacion: CLLocation?) throws -> Captura {
        let nombre = Self.nombreNuevo()
        let relativa = "fotos/\(nombre).jpg"
        guard let datos = imagen.jpegData(compressionQuality: 0.9) else { throw ErrorAlmacen.imagenInvalida }
        try datos.write(to: raiz.appendingPathComponent(relativa))

        let captura = nuevaCaptura(tipo: .foto, archivo: relativa, album: album, ubicacion: ubicacion)
        captura.filtro = filtro.rawValue
        captura.miniatura = try guardarMiniatura(de: imagen, nombre: nombre)
        persistencia.guardar()
        return captura
    }

    @discardableResult
    func guardarAudio(en url: URL, duracion: TimeInterval, album: Album?, ubicacion: CLLocation?) -> Captura {
        let relativa = "audios/\(url.lastPathComponent)"
        let captura = nuevaCaptura(tipo: .audio, archivo: relativa, album: album, ubicacion: ubicacion)
        captura.duracion = duracion
        persistencia.guardar()
        return captura
    }

    /// Reemplaza la foto tras editarla (giro, recorte o filtro).
    func actualizarFoto(_ captura: Captura, con imagen: UIImage, filtro: FiltroFoto?) throws {
        guard let datos = imagen.jpegData(compressionQuality: 0.9) else { throw ErrorAlmacen.imagenInvalida }
        try datos.write(to: url(de: captura), options: .atomic)
        let nombre = url(de: captura).deletingPathExtension().lastPathComponent
        captura.miniatura = try guardarMiniatura(de: imagen, nombre: nombre)
        cacheMiniaturas.removeObject(forKey: nombre as NSString)
        if let filtro { captura.filtro = filtro.rawValue }
        persistencia.guardar()
        objectWillChange.send()
    }

    // MARK: Importar / eliminar

    /// Importa una imagen o audio elegido con el selector de archivos.
    func importar(_ externo: URL, album: Album?) throws {
        let acceso = externo.startAccessingSecurityScopedResource()
        defer { if acceso { externo.stopAccessingSecurityScopedResource() } }
        let ext = externo.pathExtension.lowercased()
        if ["jpg", "jpeg", "png", "heic", "gif", "webp"].contains(ext) {
            guard let imagen = UIImage(contentsOfFile: externo.path) else { throw ErrorAlmacen.imagenInvalida }
            try guardarFoto(imagen, filtro: .ninguno, album: album, ubicacion: nil)
        } else if ["m4a", "mp3", "wav", "aac", "caf"].contains(ext) {
            let destino = raiz.appendingPathComponent("audios/\(Self.nombreNuevo()).\(ext)")
            try fm.copyItem(at: externo, to: destino)
            let duracion = ReproductorAudio.duracion(de: destino)
            guardarAudio(en: destino, duracion: duracion, album: album, ubicacion: nil)
        } else {
            throw ErrorAlmacen.tipoNoSoportado(ext)
        }
    }

    func eliminar(_ captura: Captura) {
        try? fm.removeItem(at: url(de: captura))
        if let mini = captura.miniatura { try? fm.removeItem(at: raiz.appendingPathComponent(mini)) }
        contexto.delete(captura)
        persistencia.guardar()
    }

    // MARK: Álbumes y metadatos

    @discardableResult
    func crearAlbum(_ nombre: String) -> Album? {
        let limpio = nombre.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !limpio.isEmpty else { return nil }
        let album = Album(context: contexto)
        album.id = UUID()
        album.nombre = limpio
        album.fecha = Date()
        persistencia.guardar()
        return album
    }

    func eliminarAlbum(_ album: Album) {
        contexto.delete(album) // Las capturas quedan sin álbum (regla Nullify).
        persistencia.guardar()
    }

    func guardarCambios() {
        persistencia.guardar()
        objectWillChange.send()
    }

    // MARK: Miniaturas (disco + NSCache)

    func miniatura(de captura: Captura) -> UIImage? {
        guard let relativa = captura.miniatura else { return nil }
        let clave = relativa as NSString
        if let img = cacheMiniaturas.object(forKey: clave) { return img }
        guard let img = UIImage(contentsOfFile: raiz.appendingPathComponent(relativa).path) else { return nil }
        cacheMiniaturas.setObject(img, forKey: clave)
        return img
    }

    private func guardarMiniatura(de imagen: UIImage, nombre: String) throws -> String {
        let relativa = "miniaturas/\(nombre).jpg"
        let lado: CGFloat = 300
        let escala = lado / max(imagen.size.width, imagen.size.height)
        let tamano = CGSize(width: imagen.size.width * escala, height: imagen.size.height * escala)
        let formato = UIGraphicsImageRendererFormat()
        formato.scale = 1
        let chica = UIGraphicsImageRenderer(size: tamano, format: formato).image { _ in
            imagen.draw(in: CGRect(origin: .zero, size: tamano))
        }
        try chica.jpegData(compressionQuality: 0.7)?.write(to: raiz.appendingPathComponent(relativa))
        cacheMiniaturas.setObject(chica, forKey: relativa as NSString)
        return relativa
    }

    private func nuevaCaptura(tipo: TipoCaptura, archivo: String, album: Album?, ubicacion: CLLocation?) -> Captura {
        let c = Captura(context: contexto)
        c.id = UUID()
        c.tipo = tipo.rawValue
        c.archivo = archivo
        c.fecha = Date()
        c.etiquetas = ""
        c.album = album
        if let ubicacion {
            c.latitud = NSNumber(value: ubicacion.coordinate.latitude)
            c.longitud = NSNumber(value: ubicacion.coordinate.longitude)
        }
        return c
    }

    private static func nombreNuevo() -> String {
        let formato = DateFormatter()
        formato.dateFormat = "yyyyMMdd_HHmmss_SSS"
        return formato.string(from: Date())
    }
}
