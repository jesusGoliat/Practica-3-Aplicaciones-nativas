import SwiftUI

/// Raíz del explorador: ubicaciones del sandbox y carpetas externas
/// autorizadas. Restaura la última carpeta visitada al abrir la app.
struct ExploradorView: View {
    @EnvironmentObject private var prefs: Preferencias
    @EnvironmentObject private var externas: CarpetasExternas
    @State private var ruta: [Destino] = []
    @State private var restaurada = false
    @State private var agregandoExterna = false
    @State private var error: String?

    private let servicio = ServicioArchivos.compartido

    var body: some View {
        NavigationStack(path: $ruta) {
            List {
                Section("En este iPhone") {
                    ForEach(servicio.raices) { raiz in
                        NavigationLink(value: Destino.carpeta(raiz.url)) {
                            Label(raiz.nombre, systemImage: raiz.icono)
                        }
                    }
                }
                Section {
                    ForEach(externas.carpetas) { carpeta in
                        Button {
                            abrir(carpeta)
                        } label: {
                            Label(carpeta.nombre, systemImage: "externaldrive")
                        }
                        .swipeActions {
                            Button("Quitar", role: .destructive) { externas.quitar(carpeta) }
                        }
                    }
                    Button {
                        agregandoExterna = true
                    } label: {
                        Label("Agregar carpeta de Archivos…", systemImage: "plus.circle")
                    }
                } header: {
                    Text("Otras ubicaciones")
                } footer: {
                    Text("El acceso a carpetas de la app Archivos o iCloud Drive se conserva con marcadores de seguridad (security-scoped bookmarks).")
                }
            }
            .navigationTitle("Ubicaciones")
            .navigationDestination(for: Destino.self) { $0.vista }
            .sheet(isPresented: $agregandoExterna) {
                SelectorDocumentos(tipos: [.folder], comoCopia: false, multiple: false) { urls in
                    guard let url = urls.first else { return }
                    do { try externas.agregar(url) } catch { self.error = error.localizedDescription }
                }
            }
            .alert("Error", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
                Button("Aceptar", role: .cancel) {}
            } message: {
                Text(error ?? "")
            }
            .onAppear(perform: restaurarUltimaCarpeta)
        }
    }

    private func abrir(_ carpeta: CarpetaExterna) {
        do {
            ruta.append(.carpeta(try externas.abrir(carpeta)))
        } catch {
            self.error = "No se pudo abrir «\(carpeta.nombre)»: \(error.localizedDescription)"
        }
    }

    /// Reconstruye la pila de navegación hasta la última carpeta visitada.
    private func restaurarUltimaCarpeta() {
        guard !restaurada else { return }
        restaurada = true
        guard let ultima = prefs.ultimaCarpeta?.standardizedFileURL, servicio.existe(ultima),
              let raiz = servicio.raices.first(where: { ultima.path.hasPrefix($0.url.standardizedFileURL.path) })
        else { return }

        var pila: [Destino] = [.carpeta(raiz.url)]
        var actual = raiz.url.standardizedFileURL
        let resto = ultima.path.dropFirst(actual.path.count).split(separator: "/")
        for parte in resto {
            actual = actual.appendingPathComponent(String(parte), isDirectory: true)
            pila.append(.carpeta(actual))
        }
        ruta = pila
    }
}
