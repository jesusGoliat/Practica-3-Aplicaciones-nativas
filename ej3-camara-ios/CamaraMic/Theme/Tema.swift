import SwiftUI
import UIKit

/// Temas personalizables de la práctica. Cada color tiene una variante
/// para modo claro y otra para modo oscuro, así se adapta al sistema.
enum TemaApp: String, CaseIterable, Identifiable {
    case guinda
    case azul

    var id: String { rawValue }

    var nombre: String {
        switch self {
        case .guinda: return "Guinda IPN"
        case .azul: return "Azul ESCOM"
        }
    }

    /// Color dinámico: UIKit elige la variante según el modo del sistema.
    var color: Color { Color(uiColor) }

    var uiColor: UIColor {
        switch self {
        case .guinda:
            return UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0xE58FB5) : UIColor(hex: 0x6C1D45) }
        case .azul:
            return UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: 0x6CB4E4) : UIColor(hex: 0x003B5C) }
        }
    }
}

/// Permite forzar claro u oscuro; por defecto sigue al sistema.
enum Apariencia: String, CaseIterable, Identifiable {
    case sistema
    case claro
    case oscuro

    var id: String { rawValue }

    var nombre: String {
        switch self {
        case .sistema: return "Sistema"
        case .claro: return "Claro"
        case .oscuro: return "Oscuro"
        }
    }

    var esquema: ColorScheme? {
        switch self {
        case .sistema: return nil
        case .claro: return .light
        case .oscuro: return .dark
        }
    }
}

extension UIColor {
    /// Crea un color a partir de un entero 0xRRGGBB.
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}
