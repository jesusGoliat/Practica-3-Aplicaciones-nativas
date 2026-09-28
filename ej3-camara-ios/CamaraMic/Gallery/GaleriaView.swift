import CoreData
import SwiftUI
import UniformTypeIdentifiers

/// Galería integrada: fotos en cuadrícula y audios en lista, filtrables por
/// álbum. Permite crear álbumes, importar y exportar.
struct GaleriaView: View {
    @EnvironmentObject private var almacen: Almacen
    @FetchRequest(sortDescriptors: [SortDescriptor(\.fecha, order: .reverse)]) private var capturas: FetchedResults<Captura>
    @FetchRequest(sortDescriptors: [SortDescriptor(\.nombre)]) private var albumes: FetchedResults<Album>

    @State private var tipo: TipoCaptura = .foto
    @State private var albumSeleccionado: Album?
    @State private var creandoAlbum = false
    @State private var nombreAlbum = ""
    @State private var importandoFotos = false
    @State private var importandoArchivos = false
    @State private var error: String?

    private var visibles: [Captura] {
        capturas.filter { c in
            c.tipoCaptura == tipo && (albumSeleccionado == nil || c.album == albumSeleccionado)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Tipo", selection: $tipo) {
                    Label("Fotos", systemImage: "photo").tag(TipoCaptura.foto)
                    Label("Audios", systemImage: "waveform").tag(TipoCaptura.audio)
                }
                .pickerStyle(.segmented)
                .padding()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        chip("Todos", seleccionado: albumSeleccionado == nil) { albumSeleccionado = nil }
                        ForEach(albumes) { album in
                            chip(album.nombreVisible, seleccionado: albumSeleccionado == album) { albumSeleccionado = album }
                                .contextMenu {
                                    Button("Eliminar álbum", role: .destructive) {
                                        if albumSeleccionado == album { albumSeleccionado = nil }
                                        almacen.eliminarAlbum(album)
                                    }
                                }
                        }
                        Button { nombreAlbum = ""; creandoAlbum = true } label: { Image(systemName: "plus") }
                            .buttonStyle(.bordered)
                            .accessibilityLabel("Nuevo álbum")
                    }
                    .padding(.horizontal)
                }

                if visibles.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: tipo == .foto ? "photo.on.rectangle" : "waveform").font(.largeTitle)
                        Text(tipo == .foto ? "Aún no hay fotos" : "Aún no hay grabaciones")
                        Text("Captura algo o importa archivos.").font(.footnote)
                    }
                    .foregroundStyle(.secondary)
                    Spacer()
                } else if tipo == .foto {
                    cuadricula
                } else {
                    listaAudios
                }
            }
            .navigationTitle("Galería")
            .toolbar {
                Menu {
                    Button { importandoFotos = true } label: { Label("Importar de la fototeca", systemImage: "photo.on.rectangle") }
                    Button { importandoArchivos = true } label: { Label("Importar de Archivos", systemImage: "folder") }
                } label: {
                    Label("Importar", systemImage: "square.and.arrow.down")
                }
            }
            .sheet(isPresented: $importandoFotos) {
                SelectorFototeca(limite: 0) { imagenes in
                    ejecutar { for img in imagenes { try almacen.guardarFoto(img, filtro: .ninguno, album: albumSeleccionado, ubicacion: nil) } }
                }
                .ignoresSafeArea()
            }
            .fileImporter(isPresented: $importandoArchivos, allowedContentTypes: [.image, .audio], allowsMultipleSelection: true) { resultado in
                ejecutar {
                    for url in try resultado.get() { try almacen.importar(url, album: albumSeleccionado) }
                }
            }
            .alert("Nuevo álbum", isPresented: $creandoAlbum) {
                TextField("Nombre", text: $nombreAlbum)
                Button("Cancelar", role: .cancel) {}
                Button("Crear") { albumSeleccionado = almacen.crearAlbum(nombreAlbum) }
            }
            .background {
                Color.clear.alert("Error", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                    Button("Aceptar", role: .cancel) {}
                } message: {
                    Text(error ?? "")
                }
            }
        }
    }

    private var cuadricula: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 4)], spacing: 4) {
                ForEach(visibles) { foto in
                    NavigationLink {
                        DetalleFotoView(captura: foto)
                    } label: {
                        MiniaturaCaptura(captura: foto)
                            .aspectRatio(1, contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .contextMenu {
                        Button(role: .destructive) { almacen.eliminar(foto) } label: { Label("Eliminar", systemImage: "trash") }
                    }
                }
            }
            .padding(4)
        }
    }

    private var listaAudios: some View {
        List {
            ForEach(visibles) { audio in
                NavigationLink {
                    DetalleAudioView(captura: audio)
                } label: {
                    HStack {
                        Image(systemName: "waveform.circle.fill").font(.title).foregroundStyle(.tint)
                        VStack(alignment: .leading) {
                            Text(audio.fecha?.formatted(date: .abbreviated, time: .shortened) ?? "")
                            Text(resumen(audio)).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .onDelete { indices in
                indices.map { visibles[$0] }.forEach(almacen.eliminar)
            }
        }
        .listStyle(.plain)
    }

    private func resumen(_ c: Captura) -> String {
        var partes = [String(format: "%d:%02d", Int(c.duracion) / 60, Int(c.duracion) % 60)]
        if let album = c.album { partes.append(album.nombreVisible) }
        partes += c.listaEtiquetas.map { "#\($0)" }
        return partes.joined(separator: " · ")
    }

    private func chip(_ texto: String, seleccionado: Bool, accion: @escaping () -> Void) -> some View {
        Button(texto, action: accion)
            .buttonStyle(.bordered)
            .tint(seleccionado ? Color.accentColor : Color.secondary)
    }

    private func ejecutar(_ operacion: () throws -> Void) {
        do { try operacion() } catch { self.error = error.localizedDescription }
    }
}

/// Miniatura desde la caché del almacén.
struct MiniaturaCaptura: View {
    @EnvironmentObject private var almacen: Almacen
    @ObservedObject var captura: Captura

    var body: some View {
        Color.secondary.opacity(0.2)
            .overlay {
                if let img = almacen.miniatura(de: captura) {
                    Image(uiImage: img).resizable().scaledToFill()
                } else {
                    Image(systemName: "photo").foregroundStyle(.secondary)
                }
            }
            .clipped()
    }
}
