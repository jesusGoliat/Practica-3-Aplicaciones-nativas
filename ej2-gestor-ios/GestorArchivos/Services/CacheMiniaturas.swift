import CryptoKit
import QuickLookThumbnailing
import UIKit

/// Caché de miniaturas en dos niveles: memoria (NSCache) y disco
/// (Library/Caches/Miniaturas). La clave incluye la fecha de modificación,
/// así una imagen editada genera una miniatura nueva.
actor CacheMiniaturas {
    static let compartida = CacheMiniaturas()

    private let memoria = NSCache<NSString, UIImage>()
    private let carpeta: URL

    init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        carpeta = caches.appendingPathComponent("Miniaturas", isDirectory: true)
        try? FileManager.default.createDirectory(at: carpeta, withIntermediateDirectories: true)
        memoria.countLimit = 300
    }

    func miniatura(para elemento: ElementoArchivo, lado: CGFloat, escala: CGFloat) async -> UIImage? {
        let clave = Self.clave(elemento, lado: lado)
        if let img = memoria.object(forKey: clave as NSString) { return img }

        let archivo = carpeta.appendingPathComponent(clave + ".png")
        if let datos = try? Data(contentsOf: archivo), let img = UIImage(data: datos) {
            memoria.setObject(img, forKey: clave as NSString)
            return img
        }

        let solicitud = QLThumbnailGenerator.Request(
            fileAt: elemento.url,
            size: CGSize(width: lado, height: lado),
            scale: escala,
            representationTypes: .thumbnail
        )
        guard let rep = try? await QLThumbnailGenerator.shared.generateBestRepresentation(for: solicitud) else {
            return nil
        }
        let img = rep.uiImage
        memoria.setObject(img, forKey: clave as NSString)
        try? img.pngData()?.write(to: archivo)
        return img
    }

    /// Borra la caché en disco y memoria (Ajustes).
    func vaciar() {
        memoria.removeAllObjects()
        try? FileManager.default.removeItem(at: carpeta)
        try? FileManager.default.createDirectory(at: carpeta, withIntermediateDirectories: true)
    }

    func tamanoEnDisco() -> Int64 {
        let urls = (try? FileManager.default.contentsOfDirectory(at: carpeta, includingPropertiesForKeys: [.fileSizeKey])) ?? []
        return urls.reduce(0) { $0 + Int64((try? $1.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0) }
    }

    private static func clave(_ e: ElementoArchivo, lado: CGFloat) -> String {
        let texto = "\(e.url.path)|\(e.fecha.timeIntervalSince1970)|\(Int(lado))"
        return SHA256.hash(data: Data(texto.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
