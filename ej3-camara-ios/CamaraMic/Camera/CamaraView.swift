import AVFoundation
import SwiftUI

/// Pantalla de captura de fotos: vista previa, flash, temporizador y
/// cambio de cámara. Tras disparar se revisa la foto y se elige el filtro.
struct CamaraView: View {
    @EnvironmentObject private var almacen: Almacen
    @EnvironmentObject private var ubicacion: ServicioUbicacion
    @StateObject private var camara = ServicioCamara()

    @State private var flash: AVCaptureDevice.FlashMode = .off
    @State private var temporizador = 0
    @State private var cuenta: Int?
    @State private var capturando = false
    @State private var destello = false
    @State private var pendiente: ImagenPendiente?
    @State private var mostrarFototeca = false
    @State private var error: String?

    private let opcionesTemporizador = [0, 3, 10]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                contenido
                if let cuenta {
                    Text("\(cuenta)")
                        .font(.system(size: 120, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(radius: 8)
                        .transition(.scale.combined(with: .opacity))
                        .id(cuenta)
                }
                // Destello blanco al disparar.
                Color.white.opacity(destello ? 0.8 : 0).ignoresSafeArea().allowsHitTesting(false)
            }
            .navigationTitle("Cámara")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { mostrarFototeca = true } label: { Label("Fototeca", systemImage: "photo.on.rectangle") }
                }
            }
            .sheet(isPresented: $mostrarFototeca) {
                SelectorFototeca { imagenes in
                    if let primera = imagenes.first { pendiente = ImagenPendiente(imagen: primera) }
                }
                .ignoresSafeArea()
            }
            .sheet(item: $pendiente) { p in
                RevisionCapturaView(imagen: p.imagen) { filtrada, filtro in
                    do {
                        try almacen.guardarFoto(filtrada, filtro: filtro, album: nil, ubicacion: ubicacion.ultima)
                    } catch {
                        self.error = error.localizedDescription
                    }
                }
            }
            .alert("Error", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("Aceptar", role: .cancel) {}
            } message: {
                Text(error ?? "")
            }
            .task {
                ubicacion.actualizar()
                if await camara.solicitarPermiso() { camara.iniciar() }
            }
            .onDisappear { camara.detener() }
        }
    }

    @ViewBuilder
    private var contenido: some View {
        if !camara.disponible {
            AvisoSinCamara(
                icono: "camera.metering.unknown",
                titulo: "Este dispositivo no tiene cámara",
                mensaje: "El simulador de iPhone no dispone de cámara física. Como fuente alternativa puedes elegir una foto de la fototeca; los filtros y la edición funcionan igual.",
                accion: "Elegir de la fototeca"
            ) { mostrarFototeca = true }
        } else if camara.autorizacion == .denied || camara.autorizacion == .restricted {
            AvisoSinCamara(
                icono: "lock.fill",
                titulo: "Sin permiso de cámara",
                mensaje: "Actívalo en Ajustes › Cámara P3 › Cámara. Mientras tanto puedes usar la fototeca.",
                accion: "Abrir Ajustes"
            ) {
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
        } else {
            VStack(spacing: 0) {
                VistaPreviaCamara(sesion: camara.sesion)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 8)
                controles
            }
        }
    }

    private var controles: some View {
        HStack {
            BotonCircular(icono: iconoFlash, etiqueta: "Flash") { cambiarFlash() }
                .disabled(!camara.tieneFlash)
            BotonCircular(icono: "timer", etiqueta: temporizador == 0 ? "Temporizador apagado" : "\(temporizador) s",
                          insignia: temporizador == 0 ? nil : "\(temporizador)") {
                let i = opcionesTemporizador.firstIndex(of: temporizador) ?? 0
                temporizador = opcionesTemporizador[(i + 1) % opcionesTemporizador.count]
            }
            Spacer()
            BotonDisparo(ocupado: capturando) { Task { await disparar() } }
            Spacer()
            BotonCircular(icono: "arrow.triangle.2.circlepath.camera", etiqueta: "Cambiar cámara") { camara.cambiarCamara() }
            BotonCircular(icono: "photo.on.rectangle", etiqueta: "Fototeca") { mostrarFototeca = true }
        }
        .padding()
        .foregroundStyle(.white)
    }

    private var iconoFlash: String {
        switch flash {
        case .on: return "bolt.fill"
        case .auto: return "bolt.badge.a.fill"
        default: return "bolt.slash.fill"
        }
    }

    private func cambiarFlash() {
        switch flash {
        case .off: flash = .auto
        case .auto: flash = .on
        default: flash = .off
        }
    }

    private func disparar() async {
        guard !capturando else { return }
        capturando = true
        defer { capturando = false }
        for s in stride(from: temporizador, to: 0, by: -1) {
            withAnimation(.spring()) { cuenta = s }
            try? await Task.sleep(nanoseconds: 1_000_000_000)
        }
        withAnimation { cuenta = nil }
        do {
            let imagen = try await camara.capturar(flash: flash)
            withAnimation(.easeOut(duration: 0.1)) { destello = true }
            withAnimation(.easeIn(duration: 0.3).delay(0.1)) { destello = false }
            pendiente = ImagenPendiente(imagen: imagen)
        } catch {
            self.error = "No se pudo tomar la foto: \(error.localizedDescription)"
        }
    }
}

/// Revisión previa al guardado: se elige el filtro y se ve el resultado.
struct RevisionCapturaView: View {
    let imagen: UIImage
    let alGuardar: (UIImage, FiltroFoto) -> Void

    @Environment(\.dismiss) private var cerrar
    @State private var filtro: FiltroFoto = .ninguno
    @State private var vista: UIImage?

    var body: some View {
        NavigationStack {
            VStack {
                Image(uiImage: vista ?? imagen)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: .infinity)
                    .animation(.easeInOut, value: filtro)
                SelectorFiltro(filtro: $filtro)
            }
            .padding(.vertical)
            .navigationTitle("Revisar foto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Descartar", role: .destructive) { cerrar() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        alGuardar(vista ?? imagen, filtro)
                        cerrar()
                    }
                }
            }
            .task(id: filtro) {
                let base = imagen
                let f = filtro
                vista = await Task.detached { f.aplicar(a: base) }.value
            }
        }
    }
}

/// Carrusel horizontal de filtros.
struct SelectorFiltro: View {
    @Binding var filtro: FiltroFoto

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(FiltroFoto.allCases) { f in
                    Button(f.nombre) { withAnimation { filtro = f } }
                        .buttonStyle(.bordered)
                        .tint(f == filtro ? Color.accentColor : Color.secondary)
                        .accessibilityAddTraits(f == filtro ? .isSelected : [])
                }
            }
            .padding(.horizontal)
        }
    }
}

/// Botón redondo para los controles de captura.
struct BotonCircular: View {
    let icono: String
    let etiqueta: String
    var insignia: String?
    let accion: () -> Void

    var body: some View {
        Button(action: accion) {
            Image(systemName: icono)
                .font(.title3)
                .frame(width: 44, height: 44)
                .background(.ultraThinMaterial, in: Circle())
                .overlay(alignment: .topTrailing) {
                    if let insignia {
                        Text(insignia).font(.caption2.bold()).padding(3).background(.tint, in: Capsule())
                    }
                }
        }
        .accessibilityLabel(etiqueta)
    }
}

/// Disparador con animación de pulsación.
struct BotonDisparo: View {
    let ocupado: Bool
    let accion: () -> Void
    @State private var presionado = false

    var body: some View {
        Button(action: accion) {
            ZStack {
                Circle().stroke(.white, lineWidth: 4).frame(width: 74, height: 74)
                Circle().fill(ocupado ? Color.gray : Color.white).frame(width: 60, height: 60)
                    .scaleEffect(presionado ? 0.85 : 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(ocupado)
        .simultaneousGesture(DragGesture(minimumDistance: 0)
            .onChanged { _ in withAnimation(.easeOut(duration: 0.1)) { presionado = true } }
            .onEnded { _ in withAnimation(.spring()) { presionado = false } })
        .accessibilityLabel("Tomar foto")
    }
}

/// Aviso cuando no hay cámara o no hay permiso.
struct AvisoSinCamara: View {
    let icono: String
    let titulo: String
    let mensaje: String
    let accion: String
    let alPulsar: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icono).font(.system(size: 56)).foregroundStyle(.tint)
            Text(titulo).font(.title2.bold()).multilineTextAlignment(.center)
            Text(mensaje).multilineTextAlignment(.center).foregroundStyle(.secondary)
            Button(action: alPulsar) { Label(accion, systemImage: "photo.on.rectangle") }
                .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
        .padding()
    }
}
