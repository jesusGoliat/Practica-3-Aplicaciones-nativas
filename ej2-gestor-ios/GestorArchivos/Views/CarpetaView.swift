import SwiftUI

/// Copiar o mover pendiente de elegir destino.
private struct OperacionDestino: Identifiable {
    let id = UUID()
    let elemento: ElementoArchivo
    let mover: Bool
}

/// Contenido de una carpeta con búsqueda, orden, gestos y operaciones.
///
/// Gestos de iOS: deslizar a la izquierda para eliminar (con confirmación),
/// deslizar a la derecha para favorito, mantener presionado para el menú
/// contextual y deslizar hacia abajo para actualizar.
struct CarpetaView: View {
    let url: URL

    @EnvironmentObject private var prefs: Preferencias
    @State private var elementos: [ElementoArchivo] = []
    @State private var busqueda = ""
    @State private var error: String?
    @State private var creandoCarpeta = false
    @State private var nombreNuevo = ""
    @State private var renombrando: ElementoArchivo?
    @State private var porEliminar: ElementoArchivo?
    @State private var importando = false
    @State private var compartir: URLIdentificable?
    @State private var previa: URLIdentificable?
    @State private var operacion: OperacionDestino?

    private let servicio = ServicioArchivos.compartido

    private var visibles: [ElementoArchivo] {
        elementos.filtrados(por: busqueda).ordenados(por: prefs.orden, ascendente: prefs.ascendente)
    }

    var body: some View {
        List {
            Section {
                ForEach(visibles) { elemento in
                    EnlaceArchivo(elemento: elemento) {
                        FilaArchivo(elemento: elemento, esFavorito: prefs.esFavorito(elemento.url))
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) { porEliminar = elemento } label: { Label("Eliminar", systemImage: "trash") }
                    }
                    .swipeActions(edge: .leading) {
                        Button { prefs.alternarFavorito(elemento.url) } label: {
                            Label("Favorito", systemImage: prefs.esFavorito(elemento.url) ? "star.slash" : "star")
                        }
                        .tint(.yellow)
                    }
                    .contextMenu { menuContextual(elemento) }
                }
            } header: {
                RutaView(url: url)
            }
        }
        .overlay {
            if visibles.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: busqueda.isEmpty ? "folder" : "magnifyingglass").font(.largeTitle)
                    Text(busqueda.isEmpty ? "Carpeta vacía" : "Sin resultados para «\(busqueda)»")
                }
                .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(url.lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $busqueda, prompt: "Buscar en esta carpeta")
        .refreshable { cargar() }
        .toolbar { barra }
        .onAppear {
            cargar()
            if servicio.estaEnSandbox(url) { prefs.ultimaCarpeta = url }
        }
        // Hojas y diálogos.
        .sheet(isPresented: $importando) {
            SelectorDocumentos(tipos: [.item]) { urls in
                ejecutar { for externo in urls { _ = try servicio.importar(externo, a: url) } }
            }
        }
        .sheet(item: $compartir) { HojaCompartir(elementos: [$0.url]).presentationDetents([.medium, .large]) }
        .sheet(item: $previa) { VistaQuickLook(url: $0.url).ignoresSafeArea() }
        .sheet(item: $operacion) { op in
            SelectorDestinoView(titulo: op.mover ? "Mover a…" : "Copiar a…") { carpeta in
                ejecutar {
                    if op.mover {
                        let nueva = try servicio.mover(op.elemento.url, a: carpeta)
                        prefs.rutaCambio(de: op.elemento.url, a: nueva)
                    } else {
                        _ = try servicio.copiar(op.elemento.url, a: carpeta)
                    }
                }
            }
        }
        .confirmationDialog(
            "¿Eliminar «\(porEliminar?.nombre ?? "")»?",
            isPresented: Binding(get: { porEliminar != nil }, set: { if !$0 { porEliminar = nil } }),
            titleVisibility: .visible,
            presenting: porEliminar
        ) { elemento in
            Button("Eliminar", role: .destructive) {
                ejecutar {
                    try servicio.eliminar(elemento.url)
                    prefs.rutaCambio(de: elemento.url, a: nil)
                }
            }
        } message: { elemento in
            Text(elemento.esCarpeta ? "Se borrará la carpeta y todo su contenido." : "Esta acción no se puede deshacer.")
        }
        .alert("Nueva carpeta", isPresented: $creandoCarpeta) {
            TextField("Nombre", text: $nombreNuevo)
            Button("Cancelar", role: .cancel) {}
            Button("Crear") { ejecutar { try servicio.crearCarpeta(nombreNuevo, en: url) } }
        }
        .background {
            // Alertas en otra vista para que no choquen entre sí.
            Color.clear
                .alert("Renombrar", isPresented: Binding(get: { renombrando != nil }, set: { if !$0 { renombrando = nil } })) {
                    TextField("Nombre", text: $nombreNuevo)
                    Button("Cancelar", role: .cancel) {}
                    Button("Guardar") {
                        guard let elemento = renombrando else { return }
                        ejecutar {
                            let nueva = try servicio.renombrar(elemento.url, a: nombreNuevo)
                            prefs.rutaCambio(de: elemento.url, a: nueva)
                        }
                    }
                }
            Color.clear
                .alert("Error", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                    Button("Aceptar", role: .cancel) {}
                } message: {
                    Text(error ?? "")
                }
        }
    }

    // MARK: Barra y menús

    @ToolbarContentBuilder
    private var barra: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Picker("Ordenar por", selection: $prefs.orden) {
                    ForEach(CriterioOrden.allCases) { Text($0.nombre).tag($0) }
                }
                Toggle(isOn: $prefs.ascendente) { Label("Ascendente", systemImage: "arrow.up") }
                Divider()
                Button { nombreNuevo = ""; creandoCarpeta = true } label: { Label("Nueva carpeta", systemImage: "folder.badge.plus") }
                Button { importando = true } label: { Label("Importar desde Archivos", systemImage: "square.and.arrow.down") }
            } label: {
                Label("Opciones", systemImage: "ellipsis.circle")
            }
        }
    }

    @ViewBuilder
    private func menuContextual(_ elemento: ElementoArchivo) -> some View {
        if !elemento.esCarpeta {
            Button { abrirQuickLook(elemento) } label: { Label("Vista rápida", systemImage: "eye") }
            Button { compartir = URLIdentificable(url: elemento.url) } label: { Label("Compartir", systemImage: "square.and.arrow.up") }
        }
        Button { prefs.alternarFavorito(elemento.url) } label: {
            Label(prefs.esFavorito(elemento.url) ? "Quitar de favoritos" : "Agregar a favoritos",
                  systemImage: prefs.esFavorito(elemento.url) ? "star.slash" : "star")
        }
        Button { nombreNuevo = elemento.nombre; renombrando = elemento } label: { Label("Renombrar", systemImage: "pencil") }
        Button { operacion = OperacionDestino(elemento: elemento, mover: false) } label: { Label("Copiar a…", systemImage: "doc.on.doc") }
        Button { operacion = OperacionDestino(elemento: elemento, mover: true) } label: { Label("Mover a…", systemImage: "folder") }
        Divider()
        Button(role: .destructive) { porEliminar = elemento } label: { Label("Eliminar", systemImage: "trash") }
    }

    // MARK: Acciones

    private func cargar() {
        do {
            elementos = try servicio.listar(url)
        } catch {
            elementos = []
            self.error = "No se pudo leer la carpeta: \(error.localizedDescription)"
        }
    }

    private func abrirQuickLook(_ elemento: ElementoArchivo) {
        if VistaQuickLook.puedeMostrar(elemento.url) {
            prefs.registrarReciente(elemento.url)
            previa = URLIdentificable(url: elemento.url)
        } else {
            error = ErrorArchivo.tipoNoSoportado(elemento.url.pathExtension).localizedDescription
        }
    }

    /// Ejecuta una operación y muestra el error, si lo hay, con un mensaje claro.
    private func ejecutar(_ operacion: () throws -> Void) {
        do {
            try operacion()
        } catch {
            self.error = error.localizedDescription
        }
        cargar()
    }
}

/// Muestra la ruta actual como "Documents › Proyectos › 2026".
struct RutaView: View {
    let url: URL

    var body: some View {
        Label(partes.joined(separator: " › "), systemImage: "folder")
            .font(.footnote)
            .lineLimit(2)
            .textCase(nil)
    }

    private var partes: [String] {
        let relativa = Preferencias.relativa(url)
        let componentes = relativa.split(separator: "/").map(String.init)
        return componentes.isEmpty ? [url.lastPathComponent] : componentes
    }
}
