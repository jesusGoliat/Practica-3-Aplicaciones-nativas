import SwiftUI

/// Hoja para elegir la carpeta destino al copiar o mover.
struct SelectorDestinoView: View {
    let titulo: String
    let alElegir: (URL) -> Void

    @Environment(\.dismiss) private var cerrar

    var body: some View {
        NavigationStack {
            CarpetasDestino(url: ServicioArchivos.compartido.documentos) { carpeta in
                alElegir(carpeta)
                cerrar()
            }
            .navigationTitle(titulo)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { cerrar() } }
            }
        }
    }
}

/// Lista solo las subcarpetas; permite bajar de nivel o elegir la actual.
private struct CarpetasDestino: View {
    let url: URL
    let alElegir: (URL) -> Void

    private var subcarpetas: [ElementoArchivo] {
        ((try? ServicioArchivos.compartido.listar(url)) ?? [])
            .filter(\.esCarpeta)
            .ordenados(por: .nombre, ascendente: true)
    }

    var body: some View {
        List(subcarpetas) { carpeta in
            NavigationLink {
                CarpetasDestino(url: carpeta.url, alElegir: alElegir)
                    .navigationTitle(carpeta.nombre)
            } label: {
                Label(carpeta.nombre, systemImage: "folder")
            }
        }
        .overlay { if subcarpetas.isEmpty { Text("Sin subcarpetas").foregroundStyle(.secondary) } }
        .safeAreaInset(edge: .bottom) {
            Button {
                alElegir(url)
            } label: {
                Text("Elegir «\(url.lastPathComponent)»").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }
}
