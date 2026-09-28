import SwiftUI

/// Grabadora: medidor animado, pausa, sensibilidad y temporizador.
struct GrabadoraView: View {
    @EnvironmentObject private var almacen: Almacen
    @EnvironmentObject private var ubicacion: ServicioUbicacion
    @StateObject private var audio = ServicioAudio()
    @State private var error: String?
    @State private var guardado: String?

    private let limites: [TimeInterval] = [0, 15, 30, 60]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 20) {
                        Text(formato(audio.transcurrido))
                            .font(.system(size: 56, weight: .light, design: .rounded).monospacedDigit())
                        if audio.limite > 0 {
                            ProgressView(value: min(audio.transcurrido, audio.limite), total: audio.limite)
                        }
                        ZStack {
                            Circle()
                                .fill(Color.accentColor.opacity(0.15 + 0.4 * Double(audio.nivel)))
                                .frame(width: 120 + 80 * CGFloat(audio.nivel), height: 120 + 80 * CGFloat(audio.nivel))
                                .animation(.easeOut(duration: 0.08), value: audio.nivel)
                            Image(systemName: audio.grabando ? "mic.fill" : "mic")
                                .font(.system(size: 48))
                                .foregroundStyle(.tint)
                        }
                        .frame(height: 200)
                        Onda(niveles: audio.historial)
                            .frame(height: 50)
                        HStack(spacing: 32) {
                            if audio.grabando {
                                Button { audio.pausarOReanudar() } label: {
                                    Image(systemName: audio.pausado ? "play.fill" : "pause.fill").font(.title)
                                }
                                .accessibilityLabel(audio.pausado ? "Reanudar" : "Pausar")
                            }
                            Button(action: alternarGrabacion) {
                                Image(systemName: audio.grabando ? "stop.circle.fill" : "record.circle")
                                    .font(.system(size: 72))
                                    .foregroundStyle(.red)
                            }
                            .accessibilityLabel(audio.grabando ? "Detener y guardar" : "Grabar")
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                Section {
                    Picker("Sensibilidad", selection: $audio.sensibilidad) {
                        ForEach(Sensibilidad.allCases) { Text($0.nombre).tag($0) }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Sensibilidad del micrófono")
                } footer: {
                    Text("Ajusta la ganancia de entrada (en dispositivos que lo permiten), la calidad y el umbral del medidor.")
                }
                Section("Temporizador de grabación") {
                    Picker("Límite", selection: $audio.limite) {
                        ForEach(limites, id: \.self) { Text($0 == 0 ? "Sin límite" : "\(Int($0)) s").tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
                .disabled(audio.grabando)
                if audio.permiso == false {
                    Section {
                        Label("Sin permiso de micrófono. Actívalo en Ajustes › Cámara P3.", systemImage: "mic.slash")
                        Button("Abrir Ajustes") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                        }
                    }
                }
            }
            .navigationTitle("Grabadora")
            .alert("Error", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("Aceptar", role: .cancel) {}
            } message: {
                Text(error ?? "")
            }
            .overlay(alignment: .bottom) {
                if let guardado {
                    Label(guardado, systemImage: "checkmark.circle.fill")
                        .padding()
                        .background(.regularMaterial, in: Capsule())
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom)
                }
            }
            .onAppear {
                audio.alTerminar = { url, duracion in
                    almacen.guardarAudio(en: url, duracion: duracion, album: nil, ubicacion: ubicacion.ultima)
                    withAnimation { guardado = "Grabación guardada (\(formato(duracion)))" }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { withAnimation { guardado = nil } }
                }
            }
        }
    }

    private func alternarGrabacion() {
        if audio.grabando {
            audio.detener()
            return
        }
        Task {
            guard await audio.solicitarPermiso() else { return }
            do {
                try audio.iniciar(en: almacen.urlNuevaGrabacion())
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    private func formato(_ t: TimeInterval) -> String {
        String(format: "%02d:%02d", Int(t) / 60, Int(t) % 60)
    }
}

/// Historial del nivel de audio como barras.
struct Onda: View {
    let niveles: [Float]

    var body: some View {
        Canvas { ctx, tamano in
            let paso = tamano.width / 80
            for (i, n) in niveles.enumerated() {
                let x = tamano.width - CGFloat(niveles.count - i) * paso
                let alto = max(2, CGFloat(n) * tamano.height)
                let barra = CGRect(x: x, y: (tamano.height - alto) / 2, width: max(1, paso - 1), height: alto)
                ctx.fill(Path(roundedRect: barra, cornerRadius: 1), with: .color(.accentColor))
            }
        }
        .accessibilityHidden(true)
    }
}
