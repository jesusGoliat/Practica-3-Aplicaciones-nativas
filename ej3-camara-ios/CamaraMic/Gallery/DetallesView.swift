import SwiftUI

/// Visor de una foto: zoom con pellizco, metadatos y edición básica.
struct DetalleFotoView: View {
    @EnvironmentObject private var almacen: Almacen
    @Environment(\.dismiss) private var cerrar
    @ObservedObject var captura: Captura

    @State private var imagen: UIImage?
    @State private var escala: CGFloat = 1
    @GestureState private var escalaGesto: CGFloat = 1
    @State private var editando = false
    @State private var metadatos = false
    @State private var compartir = false
    @State private var confirmarBorrado = false

    var body: some View {
        VStack {
            if let imagen {
                Image(uiImage: imagen)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(escala * escalaGesto)
                    .gesture(MagnificationGesture()
                        .updating($escalaGesto) { v, s, _ in s = v }
                        .onEnded { escala = min(max(escala * $0, 1), 5) })
                    .onTapGesture(count: 2) { withAnimation(.spring()) { escala = 1 } }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                AvisoSinCamara(icono: "exclamationmark.triangle", titulo: "Archivo no disponible",
                               mensaje: ErrorAlmacen.imagenInvalida.localizedDescription, accion: "Eliminar registro") {
                    almacen.eliminar(captura)
                    cerrar()
                }
            }
            InfoCaptura(captura: captura)
        }
        .navigationTitle("Foto")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button { editando = true } label: { Label("Editar", systemImage: "slider.horizontal.3") }.disabled(imagen == nil)
                Spacer()
                Button { metadatos = true } label: { Label("Etiquetas", systemImage: "tag") }
                Spacer()
                Button { compartir = true } label: { Label("Exportar", systemImage: "square.and.arrow.up") }
                Spacer()
                Button(role: .destructive) { confirmarBorrado = true } label: { Label("Eliminar", systemImage: "trash") }
            }
        }
        .sheet(isPresented: $editando) {
            if let imagen {
                EditorFotoView(original: imagen) { editada, filtro in
                    try? almacen.actualizarFoto(captura, con: editada, filtro: filtro)
                    self.imagen = editada
                }
            }
        }
        .sheet(isPresented: $metadatos) { EditorMetadatosView(captura: captura) }
        .sheet(isPresented: $compartir) { HojaCompartir(elementos: [almacen.url(de: captura)]).presentationDetents([.medium, .large]) }
        .confirmationDialog("¿Eliminar esta foto?", isPresented: $confirmarBorrado, titleVisibility: .visible) {
            Button("Eliminar", role: .destructive) {
                almacen.eliminar(captura)
                cerrar()
            }
        }
        .task { imagen = UIImage(contentsOfFile: almacen.url(de: captura).path) }
    }
}

/// Editor básico: girar, recortar cuadrado y aplicar un filtro.
struct EditorFotoView: View {
    let original: UIImage
    let alGuardar: (UIImage, FiltroFoto?) -> Void

    @Environment(\.dismiss) private var cerrar
    @State private var base: UIImage?
    @State private var filtro: FiltroFoto = .ninguno
    @State private var vista: UIImage?

    var body: some View {
        NavigationStack {
            VStack {
                Image(uiImage: vista ?? base ?? original)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: .infinity)
                HStack(spacing: 24) {
                    Button { base = (base ?? original).girada(izquierda: true) } label: { Label("Girar", systemImage: "rotate.left") }
                    Button { base = (base ?? original).girada() } label: { Label("Girar", systemImage: "rotate.right") }
                    Button { base = (base ?? original).recortadaCuadrada() } label: { Label("Recortar", systemImage: "crop") }
                }
                .labelStyle(.iconOnly)
                .font(.title2)
                SelectorFiltro(filtro: $filtro)
            }
            .padding(.vertical)
            .navigationTitle("Editar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { cerrar() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        alGuardar(vista ?? base ?? original, filtro == .ninguno ? nil : filtro)
                        cerrar()
                    }
                }
            }
            .task(id: "\(filtro.rawValue)-\(base.map { ObjectIdentifier($0).hashValue } ?? 0)") {
                let imagen = base ?? original
                let f = filtro
                vista = await Task.detached { f.aplicar(a: imagen) }.value
            }
        }
    }
}

/// Reproductor de una grabación con metadatos.
struct DetalleAudioView: View {
    @EnvironmentObject private var almacen: Almacen
    @Environment(\.dismiss) private var cerrar
    @ObservedObject var captura: Captura
    @StateObject private var reproductor = ReproductorAudio()
    @State private var metadatos = false
    @State private var compartir = false
    @State private var confirmarBorrado = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 120))
                .foregroundStyle(.tint)
                .symbolEffectCompatible(activo: reproductor.reproduciendo)
            if let error = reproductor.error {
                Text(error).foregroundStyle(.red).multilineTextAlignment(.center)
            }
            VStack {
                Slider(value: Binding(get: { reproductor.posicion }, set: { reproductor.buscar($0) }),
                       in: 0...max(reproductor.duracion, 0.1))
                HStack {
                    Text(formato(reproductor.posicion))
                    Spacer()
                    Text(formato(reproductor.duracion))
                }
                .font(.caption.monospacedDigit())
            }
            .padding(.horizontal)
            Button { reproductor.alternar() } label: {
                Image(systemName: reproductor.reproduciendo ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 72))
            }
            .accessibilityLabel(reproductor.reproduciendo ? "Pausar" : "Reproducir")
            Spacer()
            InfoCaptura(captura: captura)
        }
        .navigationTitle("Grabación")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button { metadatos = true } label: { Label("Etiquetas", systemImage: "tag") }
                Spacer()
                Button { compartir = true } label: { Label("Exportar", systemImage: "square.and.arrow.up") }
                Spacer()
                Button(role: .destructive) { confirmarBorrado = true } label: { Label("Eliminar", systemImage: "trash") }
            }
        }
        .sheet(isPresented: $metadatos) { EditorMetadatosView(captura: captura) }
        .sheet(isPresented: $compartir) { HojaCompartir(elementos: [almacen.url(de: captura)]).presentationDetents([.medium, .large]) }
        .confirmationDialog("¿Eliminar esta grabación?", isPresented: $confirmarBorrado, titleVisibility: .visible) {
            Button("Eliminar", role: .destructive) {
                reproductor.detener()
                almacen.eliminar(captura)
                cerrar()
            }
        }
        .onAppear { reproductor.cargar(almacen.url(de: captura)) }
        .onDisappear { reproductor.detener() }
    }

    private func formato(_ t: TimeInterval) -> String {
        String(format: "%d:%02d", Int(t) / 60, Int(t) % 60)
    }
}

private extension View {
    /// Pulso animado mientras suena (solo con iOS 17+).
    @ViewBuilder
    func symbolEffectCompatible(activo: Bool) -> some View {
        if #available(iOS 17.0, *) {
            symbolEffect(.pulse, isActive: activo)
        } else {
            scaleEffect(activo ? 1.05 : 1).animation(.easeInOut(duration: 0.6).repeatForever(), value: activo)
        }
    }
}

/// Metadatos guardados en Core Data.
struct InfoCaptura: View {
    @ObservedObject var captura: Captura

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(captura.fecha?.formatted(date: .long, time: .shortened) ?? "", systemImage: "calendar")
            Label(captura.textoUbicacion ?? "Sin ubicación", systemImage: "location")
            Label(captura.album?.nombreVisible ?? "Sin álbum", systemImage: "rectangle.stack")
            if let filtro = captura.filtro, let f = FiltroFoto(rawValue: filtro), f != .ninguno {
                Label("Filtro: \(f.nombre)", systemImage: "camera.filters")
            }
            if !captura.listaEtiquetas.isEmpty {
                Label(captura.listaEtiquetas.map { "#\($0)" }.joined(separator: " "), systemImage: "tag")
            }
        }
        .font(.footnote)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }
}

/// Edición de etiquetas y álbum.
struct EditorMetadatosView: View {
    @EnvironmentObject private var almacen: Almacen
    @Environment(\.dismiss) private var cerrar
    @ObservedObject var captura: Captura
    @FetchRequest(sortDescriptors: [SortDescriptor(\.nombre)]) private var albumes: FetchedResults<Album>
    @State private var etiquetas = ""
    @State private var album: Album?

    var body: some View {
        NavigationStack {
            Form {
                Section("Álbum") {
                    Picker("Álbum", selection: $album) {
                        Text("Sin álbum").tag(Album?.none)
                        ForEach(albumes) { Text($0.nombreVisible).tag(Album?.some($0)) }
                    }
                }
                Section {
                    TextField("escuela, práctica, ipn", text: $etiquetas)
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Etiquetas")
                } footer: {
                    Text("Separadas por comas.")
                }
            }
            .navigationTitle("Metadatos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { cerrar() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        captura.listaEtiquetas = etiquetas.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                        captura.album = album
                        almacen.guardarCambios()
                        cerrar()
                    }
                }
            }
            .onAppear {
                etiquetas = captura.listaEtiquetas.joined(separator: ", ")
                album = captura.album
            }
        }
        .presentationDetents([.medium])
    }
}
