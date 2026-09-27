import QuickLook
import SwiftUI
import UIKit
import UniformTypeIdentifiers

// Envoltorios de controladores UIKit que SwiftUI no ofrece directamente.

/// Selector de documentos del sistema (app Archivos / iCloud Drive).
/// Con `comoCopia` el sistema entrega una copia; sin ella se obtiene la URL
/// original con acceso de seguridad (necesario para guardar marcadores).
struct SelectorDocumentos: UIViewControllerRepresentable {
    let tipos: [UTType]
    var comoCopia = true
    var multiple = true
    let alElegir: ([URL]) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let selector = UIDocumentPickerViewController(forOpeningContentTypes: tipos, asCopy: comoCopia)
        selector.allowsMultipleSelection = multiple
        selector.delegate = context.coordinator
        return selector
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinador { Coordinador(alElegir: alElegir) }

    final class Coordinador: NSObject, UIDocumentPickerDelegate {
        let alElegir: ([URL]) -> Void
        init(alElegir: @escaping ([URL]) -> Void) { self.alElegir = alElegir }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            alElegir(urls)
        }
    }
}

/// Vista previa nativa con QLPreviewController (Quick Look).
struct VistaQuickLook: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UINavigationController {
        let previa = QLPreviewController()
        previa.dataSource = context.coordinator
        return UINavigationController(rootViewController: previa)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinador { Coordinador(url: url) }

    final class Coordinador: NSObject, QLPreviewControllerDataSource {
        let url: URL
        init(url: URL) { self.url = url }

        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }

        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as NSURL
        }
    }

    /// Indica si Quick Look sabe mostrar este archivo.
    static func puedeMostrar(_ url: URL) -> Bool {
        QLPreviewController.canPreview(url as NSURL)
    }
}

/// Hoja de compartir del sistema (UIActivityViewController).
struct HojaCompartir: UIViewControllerRepresentable {
    let elementos: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: elementos, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// URL identificable para usar con `.sheet(item:)`.
struct URLIdentificable: Identifiable {
    let url: URL
    var id: URL { url }
}
