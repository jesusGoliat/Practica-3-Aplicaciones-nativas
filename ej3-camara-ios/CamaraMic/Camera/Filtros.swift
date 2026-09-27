import CoreImage
import UIKit

/// Filtros de Core Image disponibles al capturar o editar.
enum FiltroFoto: String, CaseIterable, Identifiable {
    case ninguno, mono, noir, sepia, cromo, instantanea, invertir

    var id: String { rawValue }

    var nombre: String {
        switch self {
        case .ninguno: return "Original"
        case .mono: return "Mono"
        case .noir: return "Noir"
        case .sepia: return "Sepia"
        case .cromo: return "Cromo"
        case .instantanea: return "Instantánea"
        case .invertir: return "Negativo"
        }
    }

    private var nombreCI: String? {
        switch self {
        case .ninguno: return nil
        case .mono: return "CIPhotoEffectMono"
        case .noir: return "CIPhotoEffectNoir"
        case .sepia: return "CISepiaTone"
        case .cromo: return "CIPhotoEffectChrome"
        case .instantanea: return "CIPhotoEffectInstant"
        case .invertir: return "CIColorInvert"
        }
    }

    private static let contexto = CIContext()

    /// Aplica el filtro conservando la orientación original.
    func aplicar(a imagen: UIImage) -> UIImage {
        guard let nombreCI, let entrada = CIImage(image: imagen), let filtro = CIFilter(name: nombreCI) else { return imagen }
        filtro.setValue(entrada, forKey: kCIInputImageKey)
        if self == .sepia { filtro.setValue(0.9, forKey: kCIInputIntensityKey) }
        guard let salida = filtro.outputImage,
              let cg = Self.contexto.createCGImage(salida, from: salida.extent) else { return imagen }
        return UIImage(cgImage: cg, scale: imagen.scale, orientation: imagen.imageOrientation)
    }
}

extension UIImage {
    /// Redibuja la imagen con orientación "arriba" (evita sorpresas al girar o recortar).
    func normalizada() -> UIImage {
        guard imageOrientation != .up else { return self }
        return UIGraphicsImageRenderer(size: size).image { _ in draw(in: CGRect(origin: .zero, size: size)) }
    }

    /// Gira 90° a la derecha (o a la izquierda con `izquierda: true`).
    func girada(izquierda: Bool = false) -> UIImage {
        let base = normalizada()
        let nuevo = CGSize(width: base.size.height, height: base.size.width)
        return UIGraphicsImageRenderer(size: nuevo).image { ctx in
            let c = ctx.cgContext
            c.translateBy(x: nuevo.width / 2, y: nuevo.height / 2)
            c.rotate(by: izquierda ? -.pi / 2 : .pi / 2)
            base.draw(in: CGRect(x: -base.size.width / 2, y: -base.size.height / 2, width: base.size.width, height: base.size.height))
        }
    }

    /// Recorte cuadrado centrado.
    func recortadaCuadrada() -> UIImage {
        let base = normalizada()
        let lado = min(base.size.width, base.size.height)
        let origen = CGPoint(x: (base.size.width - lado) / 2, y: (base.size.height - lado) / 2)
        return UIGraphicsImageRenderer(size: CGSize(width: lado, height: lado)).image { _ in
            base.draw(at: CGPoint(x: -origen.x, y: -origen.y))
        }
    }
}
