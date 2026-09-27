import SwiftUI

/// Favoritos persistentes (UserDefaults).
struct FavoritosView: View {
    @EnvironmentObject private var prefs: Preferencias
    private let servicio = ServicioArchivos.compartido

    var body: some View {
        NavigationStack {
            List {
                ForEach(prefs.urlsFavoritas, id: \.self) { url in
                    if servicio.existe(url) {
                        let elemento = servicio.elemento(para: url)
                        EnlaceArchivo(elemento: elemento) { FilaArchivo(elemento: elemento, esFavorito: true) }
                            .swipeActions {
                                Button("Quitar", role: .destructive) { prefs.alternarFavorito(url) }
                            }
                    } else {
                        Label("\(url.lastPathComponent) (ya no existe)", systemImage: "questionmark.folder")
                            .foregroundStyle(.secondary)
                            .swipeActions {
                                Button("Quitar", role: .destructive) { prefs.alternarFavorito(url) }
                            }
                    }
                }
            }
            .overlay {
                if prefs.favoritos.isEmpty {
                    Text("Desliza un archivo a la derecha o mantenlo presionado para agregarlo a favoritos.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                        .padding()
                }
            }
            .navigationTitle("Favoritos")
            .navigationDestination(for: Destino.self) { $0.vista }
        }
    }
}

/// Historial de archivos abiertos recientemente.
struct RecientesView: View {
    @EnvironmentObject private var prefs: Preferencias
    private let servicio = ServicioArchivos.compartido

    var body: some View {
        NavigationStack {
            List {
                ForEach(prefs.recientes, id: \.self) { reciente in
                    let url = Preferencias.absoluta(reciente.ruta)
                    if servicio.existe(url) {
                        let elemento = servicio.elemento(para: url)
                        EnlaceArchivo(elemento: elemento) {
                            VStack(alignment: .leading) {
                                FilaArchivo(elemento: elemento, esFavorito: prefs.esFavorito(url))
                                Text("Abierto \(reciente.fecha.formatted(.relative(presentation: .named)))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Label("\(url.lastPathComponent) (ya no existe)", systemImage: "questionmark.folder")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .overlay {
                if prefs.recientes.isEmpty {
                    Text("Los archivos que abras aparecerán aquí.").foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Recientes")
            .navigationDestination(for: Destino.self) { $0.vista }
            .toolbar {
                if !prefs.recientes.isEmpty {
                    Button("Limpiar", role: .destructive) { prefs.limpiarRecientes() }
                }
            }
        }
    }
}
