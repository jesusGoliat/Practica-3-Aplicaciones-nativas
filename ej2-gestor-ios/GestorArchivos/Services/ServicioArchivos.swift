import Foundation
import UIKit

/// Errores con mensajes claros para el usuario.
enum ErrorArchivo: LocalizedError {
    case nombreInvalido
    case yaExiste(String)
    case dentroDeSiMisma
    case fueraDelSandbox
    case noEsTexto
    case imagenDanada
    case tipoNoSoportado(String)
    case sinAcceso

    var errorDescription: String? {
        switch self {
        case .nombreInvalido: return "El nombre no es válido (no puede estar vacío ni contener «/» o «:»)."
        case .yaExiste(let n): return "Ya existe un elemento llamado «\(n)» en esta carpeta."
        case .dentroDeSiMisma: return "No se puede copiar o mover una carpeta dentro de sí misma."
        case .fueraDelSandbox: return "Esa ubicación está fuera del contenedor de la app."
        case .noEsTexto: return "El archivo no contiene texto legible (puede ser binario o estar dañado)."
        case .imagenDanada: return "La imagen está dañada o su formato no es compatible."
        case .tipoNoSoportado(let ext): return "No hay vista previa para archivos «.\(ext)». Puedes compartirlo para abrirlo con otra app."
        case .sinAcceso: return "No se tiene permiso para acceder a ese archivo."
        }
    }
}

/// Raíz navegable del sandbox.
struct Raiz: Identifiable, Hashable {
    let nombre: String
    let icono: String
    let url: URL
    var id: URL { url }
}

/// Operaciones sobre el sistema de archivos con FileManager.
struct ServicioArchivos {
    static let compartido = ServicioArchivos()
    private let fm = FileManager.default

    var documentos: URL { fm.urls(for: .documentDirectory, in: .userDomainMask)[0] }
    var inbox: URL { documentos.appendingPathComponent("Inbox", isDirectory: true) }
    var temporales: URL { fm.temporaryDirectory }

    /// Directorios accesibles para la app dentro de su contenedor.
    var raices: [Raiz] {
        [
            Raiz(nombre: "Documents", icono: "folder", url: documentos),
            Raiz(nombre: "Inbox", icono: "tray.and.arrow.down", url: inbox),
            Raiz(nombre: "tmp", icono: "clock.arrow.circlepath", url: temporales),
        ]
    }

    /// Indica si una URL está dentro del contenedor de la app.
    func estaEnSandbox(_ url: URL) -> Bool {
        let hogar = URL(fileURLWithPath: NSHomeDirectory()).resolvingSymlinksInPath().path
        return url.resolvingSymlinksInPath().path.hasPrefix(hogar)
    }

    // MARK: Lectura

    func listar(_ carpeta: URL) throws -> [ElementoArchivo] {
        let claves: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey]
        let urls = try fm.contentsOfDirectory(at: carpeta, includingPropertiesForKeys: claves, options: [.skipsHiddenFiles])
        return urls.map(elemento(para:))
    }

    func elemento(para url: URL) -> ElementoArchivo {
        let v = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
        return ElementoArchivo(
            url: url,
            nombre: url.lastPathComponent,
            esCarpeta: v?.isDirectory ?? false,
            tamano: Int64(v?.fileSize ?? 0),
            fecha: v?.contentModificationDate ?? .distantPast
        )
    }

    func existe(_ url: URL) -> Bool { fm.fileExists(atPath: url.path) }

    /// Lee un archivo de texto; rechaza binarios y archivos muy grandes.
    func leerTexto(_ url: URL) throws -> String {
        let datos = try Data(contentsOf: url, options: .mappedIfSafe)
        if datos.count > 2_000_000 { return String(decoding: datos.prefix(2_000_000), as: UTF8.self) + "\n…(archivo recortado)" }
        if datos.contains(0) { throw ErrorArchivo.noEsTexto }
        if let texto = String(data: datos, encoding: .utf8) ?? String(data: datos, encoding: .isoLatin1) { return texto }
        throw ErrorArchivo.noEsTexto
    }

    // MARK: Gestión

    func validar(_ nombre: String) throws -> String {
        let limpio = nombre.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !limpio.isEmpty, !limpio.contains("/"), !limpio.contains(":"), limpio != ".", limpio != ".." else {
            throw ErrorArchivo.nombreInvalido
        }
        return limpio
    }

    @discardableResult
    func crearCarpeta(_ nombre: String, en carpeta: URL) throws -> URL {
        let destino = carpeta.appendingPathComponent(try validar(nombre), isDirectory: true)
        if existe(destino) { throw ErrorArchivo.yaExiste(destino.lastPathComponent) }
        try fm.createDirectory(at: destino, withIntermediateDirectories: false)
        return destino
    }

    func renombrar(_ url: URL, a nombre: String) throws -> URL {
        let destino = url.deletingLastPathComponent().appendingPathComponent(try validar(nombre))
        if destino == url { return url }
        if existe(destino) { throw ErrorArchivo.yaExiste(destino.lastPathComponent) }
        try fm.moveItem(at: url, to: destino)
        return destino
    }

    func copiar(_ url: URL, a carpeta: URL) throws -> URL {
        try verificarDestino(url, carpeta)
        let destino = carpeta.appendingPathComponent(nombreLibre(url.lastPathComponent, en: carpeta))
        try fm.copyItem(at: url, to: destino)
        return destino
    }

    func mover(_ url: URL, a carpeta: URL) throws -> URL {
        try verificarDestino(url, carpeta)
        if url.deletingLastPathComponent().standardizedFileURL == carpeta.standardizedFileURL { return url }
        let destino = carpeta.appendingPathComponent(nombreLibre(url.lastPathComponent, en: carpeta))
        try fm.moveItem(at: url, to: destino)
        return destino
    }

    func eliminar(_ url: URL) throws {
        try fm.removeItem(at: url)
    }

    /// Copia un archivo elegido con el selector de documentos. El acceso con
    /// alcance de seguridad se abre y se cierra alrededor de la copia.
    func importar(_ externo: URL, a carpeta: URL) throws -> URL {
        let acceso = externo.startAccessingSecurityScopedResource()
        defer { if acceso { externo.stopAccessingSecurityScopedResource() } }
        let destino = carpeta.appendingPathComponent(nombreLibre(externo.lastPathComponent, en: carpeta))
        try fm.copyItem(at: externo, to: destino)
        return destino
    }

    /// "foto.png" → "foto (1).png" si ya existe.
    func nombreLibre(_ nombre: String, en carpeta: URL) -> String {
        guard existe(carpeta.appendingPathComponent(nombre)) else { return nombre }
        let base = (nombre as NSString).deletingPathExtension
        let ext = (nombre as NSString).pathExtension
        var i = 1
        while true {
            let candidato = ext.isEmpty ? "\(base) (\(i))" : "\(base) (\(i)).\(ext)"
            if !existe(carpeta.appendingPathComponent(candidato)) { return candidato }
            i += 1
        }
    }

    private func verificarDestino(_ url: URL, _ carpeta: URL) throws {
        let origen = url.standardizedFileURL.path
        let dest = carpeta.standardizedFileURL.path
        if dest == origen || dest.hasPrefix(origen + "/") { throw ErrorArchivo.dentroDeSiMisma }
    }

    // MARK: Archivos de ejemplo

    /// Crea Inbox y, en el primer arranque, archivos de ejemplo de cada tipo
    /// para poder probar el explorador en el simulador.
    func prepararSandbox() {
        try? fm.createDirectory(at: inbox, withIntermediateDirectories: true)
        let marca = "ejemplosCreados"
        guard !UserDefaults.standard.bool(forKey: marca) else { return }
        defer { UserDefaults.standard.set(true, forKey: marca) }

        let docs = documentos
        let proyectos = docs.appendingPathComponent("Proyectos/2026", isDirectory: true)
        let imagenes = docs.appendingPathComponent("Imágenes", isDirectory: true)
        try? fm.createDirectory(at: proyectos, withIntermediateDirectories: true)
        try? fm.createDirectory(at: imagenes, withIntermediateDirectories: true)

        let textos: [(String, String)] = [
            ("Bienvenida.txt", "Gestor de archivos — Práctica 3, ESCOM-IPN.\nMantén presionado un archivo para ver más opciones."),
            ("Notas.md", "# Notas\n\n- Explorar Documents, Inbox y tmp\n- Vista previa con Quick Look\n- Temas Guinda y Azul\n"),
            ("config.json", "{\n  \"tema\": \"guinda\",\n  \"offline\": true\n}\n"),
            ("Proyectos/2026/Ejemplo.swift", "import SwiftUI\n\nstruct Hola: View {\n    var body: some View { Text(\"Hola, ESCOM\") }\n}\n"),
            ("datos.xyz", "Archivo con una extensión desconocida."),
        ]
        for (ruta, contenido) in textos {
            try? contenido.write(to: docs.appendingPathComponent(ruta), atomically: true, encoding: .utf8)
        }

        if let muestra = Bundle.main.url(forResource: "muestra", withExtension: "png") {
            try? fm.copyItem(at: muestra, to: imagenes.appendingPathComponent("escom.png"))
        }
        // Imagen dañada para demostrar el manejo de errores.
        try? Data((0..<256).map { UInt8($0 % 251) }).write(to: imagenes.appendingPathComponent("dañada.jpg"))
        crearPDFEjemplo(en: docs.appendingPathComponent("Reporte.pdf"))
        try? "Archivo temporal de prueba".write(to: temporales.appendingPathComponent("cache.txt"), atomically: true, encoding: .utf8)
    }

    private func crearPDFEjemplo(en url: URL) {
        let pagina = CGRect(x: 0, y: 0, width: 612, height: 792)
        let datos = UIGraphicsPDFRenderer(bounds: pagina).pdfData { ctx in
            ctx.beginPage()
            let titulo = "Práctica 3 — Reporte de ejemplo" as NSString
            titulo.draw(at: CGPoint(x: 72, y: 72), withAttributes: [.font: UIFont.boldSystemFont(ofSize: 24)])
            let cuerpo = "PDF generado en el dispositivo para probar Quick Look (QLPreviewController)." as NSString
            cuerpo.draw(in: CGRect(x: 72, y: 120, width: 468, height: 200), withAttributes: [.font: UIFont.systemFont(ofSize: 14)])
        }
        try? datos.write(to: url)
    }
}
