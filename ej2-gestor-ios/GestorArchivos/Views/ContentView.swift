import SwiftUI

/// Pantalla raíz con pestañas.
struct ContentView: View {
    var body: some View {
        TabView {
            ExploradorView()
                .tabItem { Label("Archivos", systemImage: "folder") }
            FavoritosView()
                .tabItem { Label("Favoritos", systemImage: "star") }
            RecientesView()
                .tabItem { Label("Recientes", systemImage: "clock") }
            AjustesView()
                .tabItem { Label("Ajustes", systemImage: "gearshape") }
        }
    }
}

/// Destinos de navegación del NavigationStack.
enum Destino: Hashable {
    case carpeta(URL)
    case texto(URL)
    case imagen(URL)

    @ViewBuilder
    var vista: some View {
        switch self {
        case .carpeta(let url): CarpetaView(url: url)
        case .texto(let url): VisorTextoView(url: url)
        case .imagen(let url): VisorImagenView(url: url)
        }
    }
}

/// Envuelve una fila y decide cómo abrir el elemento: carpetas, texto e
/// imágenes se abren en la pila de navegación; el resto con Quick Look.
struct EnlaceArchivo<Contenido: View>: View {
    let elemento: ElementoArchivo
    @ViewBuilder let contenido: () -> Contenido

    @EnvironmentObject private var prefs: Preferencias
    @State private var previa: URLIdentificable?
    @State private var aviso: String?

    var body: some View {
        switch elemento.categoria {
        case .carpeta:
            NavigationLink(value: Destino.carpeta(elemento.url), label: contenido)
        case .texto:
            NavigationLink(value: Destino.texto(elemento.url), label: contenido)
        case .imagen:
            NavigationLink(value: Destino.imagen(elemento.url), label: contenido)
        default:
            Button(action: abrirConQuickLook, label: contenido)
                .foregroundStyle(.primary)
                .sheet(item: $previa) { VistaQuickLook(url: $0.url).ignoresSafeArea() }
                .alert("No se puede abrir", isPresented: Binding(get: { aviso != nil }, set: { if !$0 { aviso = nil } })) {
                    Button("Aceptar", role: .cancel) {}
                } message: {
                    Text(aviso ?? "")
                }
        }
    }

    private func abrirConQuickLook() {
        if VistaQuickLook.puedeMostrar(elemento.url) {
            prefs.registrarReciente(elemento.url)
            previa = URLIdentificable(url: elemento.url)
        } else {
            aviso = ErrorArchivo.tipoNoSoportado(elemento.url.pathExtension).localizedDescription
        }
    }
}

/// Fila de la lista: ícono o miniatura, nombre, tamaño y fecha.
struct FilaArchivo: View {
    let elemento: ElementoArchivo
    var esFavorito = false

    var body: some View {
        HStack(spacing: 12) {
            Miniatura(elemento: elemento)
                .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(elemento.nombre).lineLimit(1)
                    if esFavorito {
                        Image(systemName: "star.fill").font(.caption).foregroundStyle(.yellow)
                            .accessibilityLabel("Favorito")
                    }
                }
                Text(detalle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var detalle: String {
        let fecha = elemento.fecha.formatted(date: .abbreviated, time: .shortened)
        return elemento.esCarpeta ? "Carpeta · \(fecha)" : "\(elemento.tamanoLegible) · \(fecha)"
    }
}

/// Miniatura de imágenes y PDF (desde la caché) o ícono según el UTType.
struct Miniatura: View {
    let elemento: ElementoArchivo
    @Environment(\.displayScale) private var escala
    @State private var imagen: UIImage?

    var body: some View {
        Group {
            if let imagen {
                Image(uiImage: imagen)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: elemento.categoria.icono)
                    .font(.title2)
                    .foregroundStyle(.tint)
            }
        }
        .task(id: elemento.fecha) {
            guard elemento.categoria == .imagen || elemento.categoria == .pdf else { return }
            imagen = await CacheMiniaturas.compartida.miniatura(para: elemento, lado: 40, escala: escala)
        }
    }
}
