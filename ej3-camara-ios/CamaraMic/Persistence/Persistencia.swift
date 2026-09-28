import CoreData

/// Pila de Core Data. Guarda los metadatos (fecha, ubicación, etiquetas,
/// álbum, filtro) de cada captura; los archivos van en Documents/Capturas.
final class Persistencia {
    static let compartida = Persistencia()

    let contenedor: NSPersistentContainer

    var contexto: NSManagedObjectContext { contenedor.viewContext }

    init(enMemoria: Bool = false) {
        contenedor = NSPersistentContainer(name: "CamaraMic")
        if enMemoria {
            contenedor.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        contenedor.loadPersistentStores { _, error in
            if let error {
                // Sin base de datos la app no puede funcionar; se registra el motivo.
                assertionFailure("No se pudo abrir Core Data: \(error)")
            }
        }
        contenedor.viewContext.automaticallyMergesChangesFromParent = true
        contenedor.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    func guardar() {
        let ctx = contenedor.viewContext
        guard ctx.hasChanges else { return }
        do {
            try ctx.save()
        } catch {
            ctx.rollback()
            print("Error al guardar Core Data: \(error)")
        }
    }
}

enum TipoCaptura: String {
    case foto
    case audio
}

// Utilidades sobre las clases que Xcode genera a partir del modelo.
extension Captura {
    var tipoCaptura: TipoCaptura { TipoCaptura(rawValue: tipo ?? "") ?? .foto }

    var listaEtiquetas: [String] {
        get { (etiquetas ?? "").split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty } }
        set { etiquetas = newValue.joined(separator: ",") }
    }

    var tieneUbicacion: Bool { latitud != nil && longitud != nil }

    var textoUbicacion: String? {
        guard let lat = latitud?.doubleValue, let lon = longitud?.doubleValue else { return nil }
        return String(format: "%.4f, %.4f", lat, lon)
    }
}

extension Album {
    var nombreVisible: String { nombre ?? "Sin nombre" }
}
