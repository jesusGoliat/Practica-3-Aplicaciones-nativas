import Foundation
import UniformTypeIdentifiers

/// Categoría visual de un archivo, derivada de su UTType.
enum Categoria {
    case carpeta, texto, imagen, pdf, audio, video, comprimido, otro

    /// Símbolo SF que se muestra en la lista.
    var icono: String {
        switch self {
        case .carpeta: return "folder.fill"
        case .texto: return "doc.text"
        case .imagen: return "photo"
        case .pdf: return "doc.richtext"
        case .audio: return "waveform"
        case .video: return "film"
        case .comprimido: return "doc.zipper"
        case .otro: return "doc"
        }
    }
}

/// Un archivo o carpeta del sistema de archivos con los datos que usa la UI.
struct ElementoArchivo: Identifiable, Hashable {
    let url: URL
    let nombre: String
    let esCarpeta: Bool
    let tamano: Int64
    let fecha: Date

    var id: URL { url }

    /// Tipo uniforme (UTType) según la extensión.
    var tipo: UTType? {
        esCarpeta ? .folder : UTType(filenameExtension: url.pathExtension)
    }

    /// Extensiones que se tratan como texto aunque el sistema no las registre así.
    private static let extensionesTexto: Set<String> = [
        "txt", "md", "markdown", "swift", "json", "xml", "csv", "log", "yml", "yaml", "kt", "dart", "html", "js", "plist",
    ]

    var categoria: Categoria {
        if esCarpeta { return .carpeta }
        let ext = url.pathExtension.lowercased()
        if Self.extensionesTexto.contains(ext) { return .texto }
        guard let tipo else { return .otro }
        if tipo.conforms(to: .image) { return .imagen }
        if tipo.conforms(to: .pdf) { return .pdf }
        if tipo.conforms(to: .audio) { return .audio }
        if tipo.conforms(to: .movie) { return .video }
        if tipo.conforms(to: .archive) { return .comprimido }
        if tipo.conforms(to: .text) || tipo.conforms(to: .sourceCode) { return .texto }
        return .otro
    }

    /// Descripción del tipo para mostrar ("Imagen PNG", "Carpeta"...).
    var descripcionTipo: String {
        if esCarpeta { return "Carpeta" }
        return tipo?.localizedDescription ?? url.pathExtension.uppercased()
    }

    var tamanoLegible: String {
        ByteCountFormatter.string(fromByteCount: tamano, countStyle: .file)
    }
}

/// Criterios de ordenamiento disponibles.
enum CriterioOrden: String, CaseIterable, Identifiable {
    case nombre, fecha, tamano

    var id: String { rawValue }

    var nombre: String {
        switch self {
        case .nombre: return "Nombre"
        case .fecha: return "Fecha"
        case .tamano: return "Tamaño"
        }
    }
}

extension Array where Element == ElementoArchivo {
    /// Ordena con las carpetas primero y luego por el criterio elegido.
    func ordenados(por criterio: CriterioOrden, ascendente: Bool) -> [ElementoArchivo] {
        sorted { a, b in
            if a.esCarpeta != b.esCarpeta { return a.esCarpeta }
            let menor: Bool
            switch criterio {
            case .nombre: menor = a.nombre.localizedStandardCompare(b.nombre) == .orderedAscending
            case .fecha: menor = a.fecha < b.fecha
            case .tamano: menor = a.tamano < b.tamano
            }
            return ascendente ? menor : !menor
        }
    }

    /// Filtra por nombre sin distinguir mayúsculas ni acentos.
    func filtrados(por texto: String) -> [ElementoArchivo] {
        let consulta = texto.trimmingCharacters(in: .whitespaces)
        guard !consulta.isEmpty else { return self }
        return filter { $0.nombre.range(of: consulta, options: [.caseInsensitive, .diacriticInsensitive]) != nil }
    }
}
