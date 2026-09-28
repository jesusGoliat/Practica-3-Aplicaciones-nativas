import AVFoundation
import Foundation

/// Nivel de sensibilidad del micrófono.
enum Sensibilidad: String, CaseIterable, Identifiable {
    case baja, media, alta

    var id: String { rawValue }
    var nombre: String { rawValue.capitalized }

    /// Ganancia de entrada (0…1) cuando el hardware permite ajustarla.
    var ganancia: Float {
        switch self {
        case .baja: return 0.3
        case .media: return 0.6
        case .alta: return 1.0
        }
    }

    /// Decibeles a partir de los cuales el medidor empieza a moverse. En el
    /// simulador la ganancia no es ajustable, así que también se usa este
    /// umbral para que la sensibilidad tenga efecto visible.
    var umbralDB: Float {
        switch self {
        case .baja: return -35
        case .media: return -50
        case .alta: return -65
        }
    }

    /// Calidad del archivo (frecuencia de muestreo).
    var frecuencia: Double {
        switch self {
        case .baja: return 22_050
        case .media: return 44_100
        case .alta: return 48_000
        }
    }
}

/// Grabación con AVAudioRecorder, medidor de nivel y límite de duración.
final class ServicioAudio: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published private(set) var grabando = false
    @Published private(set) var pausado = false
    @Published private(set) var nivel: Float = 0
    @Published private(set) var historial: [Float] = []
    @Published private(set) var transcurrido: TimeInterval = 0
    @Published private(set) var permiso: Bool?
    @Published var sensibilidad: Sensibilidad = .media
    /// Límite en segundos (0 = sin límite).
    @Published var limite: TimeInterval = 0

    /// Se llama cuando termina una grabación (manual o por el temporizador).
    var alTerminar: ((URL, TimeInterval) -> Void)?

    private var grabadora: AVAudioRecorder?
    private var reloj: Timer?

    func solicitarPermiso() async -> Bool {
        let concedido = await withCheckedContinuation { c in
            AVAudioSession.sharedInstance().requestRecordPermission { c.resume(returning: $0) }
        }
        await MainActor.run { permiso = concedido }
        return concedido
    }

    func iniciar(en url: URL) throws {
        let sesion = AVAudioSession.sharedInstance()
        try sesion.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try sesion.setActive(true)
        if sesion.isInputGainSettable { try? sesion.setInputGain(sensibilidad.ganancia) }

        let ajustes: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: sensibilidad.frecuencia,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
        ]
        let g = try AVAudioRecorder(url: url, settings: ajustes)
        g.isMeteringEnabled = true
        g.delegate = self
        let ok = limite > 0 ? g.record(forDuration: limite) : g.record()
        guard ok else { throw NSError(domain: "Audio", code: 1, userInfo: [NSLocalizedDescriptionKey: "No se pudo iniciar la grabación."]) }
        grabadora = g
        grabando = true
        pausado = false
        historial = []
        transcurrido = 0
        reloj = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in self?.medir() }
    }

    func pausarOReanudar() {
        guard let g = grabadora else { return }
        if pausado { g.record() } else { g.pause() }
        pausado.toggle()
    }

    func detener() {
        grabadora?.stop() // El delegado recibe audioRecorderDidFinishRecording.
    }

    private func medir() {
        guard let g = grabadora else { return }
        g.updateMeters()
        transcurrido = g.currentTime
        let db = g.averagePower(forChannel: 0)
        let umbral = sensibilidad.umbralDB
        nivel = max(0, min(1, (db - umbral) / -umbral))
        historial.append(nivel)
        if historial.count > 80 { historial.removeFirst(historial.count - 80) }
        // Respaldo del temporizador por si se pausó y reanudó la grabación.
        if limite > 0, g.currentTime >= limite { detener() }
    }

    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        let duracion = ReproductorAudio.duracion(de: recorder.url)
        DispatchQueue.main.async {
            self.reloj?.invalidate()
            self.reloj = nil
            self.grabadora = nil
            self.grabando = false
            self.pausado = false
            self.nivel = 0
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            if flag { self.alTerminar?(recorder.url, duracion) }
        }
    }
}

/// Reproductor de grabaciones con AVAudioPlayer.
final class ReproductorAudio: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published private(set) var reproduciendo = false
    @Published private(set) var posicion: TimeInterval = 0
    @Published private(set) var duracion: TimeInterval = 0
    @Published private(set) var error: String?

    private var jugador: AVAudioPlayer?
    private var reloj: Timer?

    static func duracion(de url: URL) -> TimeInterval {
        (try? AVAudioPlayer(contentsOf: url))?.duration ?? 0
    }

    func cargar(_ url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            let j = try AVAudioPlayer(contentsOf: url)
            j.delegate = self
            j.prepareToPlay()
            jugador = j
            duracion = j.duration
            error = nil
        } catch {
            self.error = "No se puede reproducir este archivo (puede estar dañado)."
        }
    }

    func alternar() {
        guard let j = jugador else { return }
        if j.isPlaying {
            j.pause()
            detenerReloj()
        } else {
            try? AVAudioSession.sharedInstance().setActive(true)
            j.play()
            reloj = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.posicion = self?.jugador?.currentTime ?? 0
            }
        }
        reproduciendo = j.isPlaying
    }

    func buscar(_ segundos: TimeInterval) {
        jugador?.currentTime = segundos
        posicion = segundos
    }

    func detener() {
        jugador?.stop()
        detenerReloj()
        reproduciendo = false
    }

    private func detenerReloj() {
        reloj?.invalidate()
        reloj = nil
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.detenerReloj()
            self.reproduciendo = false
            self.posicion = 0
        }
    }
}
