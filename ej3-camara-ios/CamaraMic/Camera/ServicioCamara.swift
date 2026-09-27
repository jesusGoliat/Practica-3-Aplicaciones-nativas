import AVFoundation
import UIKit

/// Captura de fotos con AVCaptureSession + AVCapturePhotoOutput.
///
/// El simulador de iOS no tiene cámara: en ese caso `disponible` es false y
/// la interfaz ofrece la fototeca (PHPickerViewController) como alternativa.
final class ServicioCamara: NSObject, ObservableObject {
    let sesion = AVCaptureSession()
    private let salida = AVCapturePhotoOutput()
    private var entrada: AVCaptureDeviceInput?
    private let cola = DispatchQueue(label: "mx.ipn.escom.p3.camara")
    private var continuacion: CheckedContinuation<UIImage, Error>?
    private var configurada = false

    @Published private(set) var disponible = AVCaptureDevice.default(for: .video) != nil
    @Published private(set) var autorizacion = AVCaptureDevice.authorizationStatus(for: .video)
    @Published private(set) var posicion: AVCaptureDevice.Position = .back
    @Published private(set) var tieneFlash = false

    /// Pide permiso de cámara en tiempo de ejecución (solo la primera vez).
    func solicitarPermiso() async -> Bool {
        if AVCaptureDevice.authorizationStatus(for: .video) == .notDetermined {
            _ = await AVCaptureDevice.requestAccess(for: .video)
        }
        let estado = AVCaptureDevice.authorizationStatus(for: .video)
        await MainActor.run { autorizacion = estado }
        return estado == .authorized
    }

    func iniciar() {
        guard disponible else { return }
        cola.async { [self] in
            if !configurada { configurar() }
            if !sesion.isRunning { sesion.startRunning() }
        }
    }

    func detener() {
        cola.async { [self] in
            if sesion.isRunning { sesion.stopRunning() }
        }
    }

    func cambiarCamara() {
        cola.async { [self] in
            let nueva: AVCaptureDevice.Position = posicion == .back ? .front : .back
            guard let dispositivo = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: nueva),
                  let nuevaEntrada = try? AVCaptureDeviceInput(device: dispositivo) else { return }
            sesion.beginConfiguration()
            if let entrada { sesion.removeInput(entrada) }
            if sesion.canAddInput(nuevaEntrada) {
                sesion.addInput(nuevaEntrada)
                entrada = nuevaEntrada
            }
            sesion.commitConfiguration()
            DispatchQueue.main.async {
                self.posicion = nueva
                self.tieneFlash = dispositivo.hasFlash
            }
        }
    }

    /// Toma una foto con el modo de flash indicado.
    func capturar(flash: AVCaptureDevice.FlashMode) async throws -> UIImage {
        try await withCheckedThrowingContinuation { c in
            cola.async { [self] in
                let ajustes = AVCapturePhotoSettings()
                if salida.supportedFlashModes.contains(flash) { ajustes.flashMode = flash }
                continuacion = c
                salida.capturePhoto(with: ajustes, delegate: self)
            }
        }
    }

    private func configurar() {
        sesion.beginConfiguration()
        sesion.sessionPreset = .photo
        if let dispositivo = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: posicion),
           let e = try? AVCaptureDeviceInput(device: dispositivo), sesion.canAddInput(e) {
            sesion.addInput(e)
            entrada = e
            DispatchQueue.main.async { self.tieneFlash = dispositivo.hasFlash }
        }
        if sesion.canAddOutput(salida) { sesion.addOutput(salida) }
        sesion.commitConfiguration()
        configurada = true
    }
}

extension ServicioCamara: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        defer { continuacion = nil }
        if let error {
            continuacion?.resume(throwing: error)
        } else if let datos = photo.fileDataRepresentation(), let imagen = UIImage(data: datos) {
            continuacion?.resume(returning: imagen)
        } else {
            continuacion?.resume(throwing: ErrorAlmacen.imagenInvalida)
        }
    }
}
