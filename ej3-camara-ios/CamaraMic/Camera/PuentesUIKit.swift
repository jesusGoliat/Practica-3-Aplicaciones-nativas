import AVFoundation
import PhotosUI
import SwiftUI
import UIKit

/// Vista previa en vivo de la cámara (AVCaptureVideoPreviewLayer).
struct VistaPreviaCamara: UIViewRepresentable {
    let sesion: AVCaptureSession

    func makeUIView(context: Context) -> VistaPrevia {
        let vista = VistaPrevia()
        vista.capa.session = sesion
        vista.capa.videoGravity = .resizeAspectFill
        return vista
    }

    func updateUIView(_ uiView: VistaPrevia, context: Context) {}

    final class VistaPrevia: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var capa: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

/// Selector de la fototeca (PHPickerViewController). Es la fuente alternativa
/// a la cámara en el simulador; no requiere permiso de fototeca.
struct SelectorFototeca: UIViewControllerRepresentable {
    var limite = 1
    let alElegir: ([UIImage]) -> Void

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = limite
        let selector = PHPickerViewController(configuration: config)
        selector.delegate = context.coordinator
        return selector
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinador { Coordinador(alElegir: alElegir) }

    final class Coordinador: NSObject, PHPickerViewControllerDelegate {
        let alElegir: ([UIImage]) -> Void
        init(alElegir: @escaping ([UIImage]) -> Void) { self.alElegir = alElegir }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            let grupo = DispatchGroup()
            var imagenes: [UIImage] = []
            for resultado in results where resultado.itemProvider.canLoadObject(ofClass: UIImage.self) {
                grupo.enter()
                resultado.itemProvider.loadObject(ofClass: UIImage.self) { objeto, _ in
                    DispatchQueue.main.async {
                        if let imagen = objeto as? UIImage { imagenes.append(imagen) }
                        grupo.leave()
                    }
                }
            }
            grupo.notify(queue: .main) { self.alElegir(imagenes) }
        }
    }
}

/// Hoja de compartir del sistema para exportar capturas.
struct HojaCompartir: UIViewControllerRepresentable {
    let elementos: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: elementos, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

/// Imagen identificable para `.sheet(item:)`.
struct ImagenPendiente: Identifiable {
    let id = UUID()
    let imagen: UIImage
}
