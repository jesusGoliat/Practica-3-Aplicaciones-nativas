import SwiftUI

/// Visor de archivos de texto (.txt, .md, .swift, .json…).
struct VisorTextoView: View {
    let url: URL

    @EnvironmentObject private var prefs: Preferencias
    @State private var texto: String?
    @State private var error: String?
    @State private var compartir = false

    var body: some View {
        Group {
            if let texto {
                ScrollView([.vertical, .horizontal]) {
                    Text(texto)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else if let error {
                AvisoError(mensaje: error)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(url.lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            Button { compartir = true } label: { Label("Compartir", systemImage: "square.and.arrow.up") }
        }
        .sheet(isPresented: $compartir) { HojaCompartir(elementos: [url]).presentationDetents([.medium, .large]) }
        .task {
            prefs.registrarReciente(url)
            do {
                let ruta = url
                texto = try await Task.detached { try ServicioArchivos.compartido.leerTexto(ruta) }.value
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}

/// Visor de imágenes: pellizcar para zoom, girar con dos dedos, arrastrar
/// cuando hay zoom y doble toque para ajustar a la pantalla.
struct VisorImagenView: View {
    let url: URL

    @EnvironmentObject private var prefs: Preferencias
    @State private var imagen: UIImage?
    @State private var error: String?
    @State private var compartir = false

    @State private var escala: CGFloat = 1
    @State private var angulo: Angle = .zero
    @State private var desplazamiento: CGSize = .zero
    @GestureState private var escalaGesto: CGFloat = 1
    @GestureState private var anguloGesto: Angle = .zero
    @GestureState private var arrastre: CGSize = .zero

    var body: some View {
        Group {
            if let imagen {
                Image(uiImage: imagen)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(escala * escalaGesto)
                    .rotationEffect(angulo + anguloGesto)
                    .offset(x: desplazamiento.width + arrastre.width, y: desplazamiento.height + arrastre.height)
                    .gesture(zoomYGiro)
                    .simultaneousGesture(arrastrar)
                    .onTapGesture(count: 2) { ajustar() }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .accessibilityLabel(url.lastPathComponent)
            } else if let error {
                AvisoError(mensaje: error)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(url.lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button { withAnimation { angulo -= .degrees(90) } } label: { Label("Girar", systemImage: "rotate.left") }
                Spacer()
                Button { ajustar() } label: { Label("Ajustar", systemImage: "arrow.down.right.and.arrow.up.left") }
                Spacer()
                Button { compartir = true } label: { Label("Compartir", systemImage: "square.and.arrow.up") }
            }
        }
        .sheet(isPresented: $compartir) { HojaCompartir(elementos: [url]).presentationDetents([.medium, .large]) }
        .task {
            prefs.registrarReciente(url)
            let ruta = url
            let cargada = await Task.detached { UIImage(contentsOfFile: ruta.path) }.value
            if let cargada { imagen = cargada } else { error = ErrorArchivo.imagenDanada.localizedDescription }
        }
    }

    private var zoomYGiro: some Gesture {
        SimultaneousGesture(
            MagnificationGesture()
                .updating($escalaGesto) { valor, estado, _ in estado = valor }
                .onEnded { escala = min(max(escala * $0, 1), 6) },
            RotationGesture()
                .updating($anguloGesto) { valor, estado, _ in estado = valor }
                .onEnded { angulo += $0 }
        )
    }

    private var arrastrar: some Gesture {
        DragGesture()
            .updating($arrastre) { valor, estado, _ in if escala > 1 { estado = valor.translation } }
            .onEnded { valor in
                guard escala > 1 else { return }
                desplazamiento.width += valor.translation.width
                desplazamiento.height += valor.translation.height
            }
    }

    private func ajustar() {
        withAnimation(.spring()) {
            escala = 1
            angulo = .zero
            desplazamiento = .zero
        }
    }
}

/// Mensaje para archivos inaccesibles, dañados o no soportados.
struct AvisoError: View {
    let mensaje: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.orange)
            Text(mensaje)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
