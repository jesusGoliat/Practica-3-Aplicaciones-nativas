import SwiftUI

/// Tema, apariencia, orden por defecto y caché de miniaturas.
struct AjustesView: View {
    @EnvironmentObject private var prefs: Preferencias
    @State private var tamanoCache: Int64 = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("Tema") {
                    Picker("Tema", selection: $prefs.tema) {
                        ForEach(TemaApp.allCases) { tema in
                            Label {
                                Text(tema.nombre)
                            } icon: {
                                Circle().fill(tema.color).frame(width: 22, height: 22)
                            }
                            .tag(tema)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section {
                    Picker("Apariencia", selection: $prefs.apariencia) {
                        ForEach(Apariencia.allCases) { Text($0.nombre).tag($0) }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Apariencia")
                } footer: {
                    Text("«Sistema» sigue el modo claro u oscuro de iOS.")
                }
                Section("Orden por defecto") {
                    Picker("Ordenar por", selection: $prefs.orden) {
                        ForEach(CriterioOrden.allCases) { Text($0.nombre).tag($0) }
                    }
                    Toggle("Ascendente", isOn: $prefs.ascendente)
                }
                Section("Almacenamiento") {
                    LabeledContent("Caché de miniaturas", value: ByteCountFormatter.string(fromByteCount: tamanoCache, countStyle: .file))
                    Button("Vaciar caché", role: .destructive) {
                        Task {
                            await CacheMiniaturas.compartida.vaciar()
                            tamanoCache = await CacheMiniaturas.compartida.tamanoEnDisco()
                        }
                    }
                    Label("Funciona sin conexión: todo se guarda en el dispositivo.", systemImage: "icloud.slash")
                        .font(.footnote)
                }
                Section("Acerca de") {
                    LabeledContent("App", value: "Gestor P3 1.0")
                    LabeledContent("Práctica", value: "3 · ESCOM-IPN")
                }
            }
            .navigationTitle("Ajustes")
            .task { tamanoCache = await CacheMiniaturas.compartida.tamanoEnDisco() }
        }
    }
}
