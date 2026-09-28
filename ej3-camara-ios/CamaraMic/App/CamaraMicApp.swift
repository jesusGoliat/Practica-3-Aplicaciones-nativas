import SwiftUI

/// Punto de entrada de la app de Cámara y Micrófono (Ejercicio 3).
/// Fotos y audios se guardan en Documents/Capturas y sus metadatos en Core
/// Data; no se usa Internet.
@main
struct CamaraMicApp: App {
    @StateObject private var almacen = Almacen.compartido
    @StateObject private var ubicacion = ServicioUbicacion()
    @AppStorage("tema") private var tema: TemaApp = .guinda
    @AppStorage("apariencia") private var apariencia: Apariencia = .sistema

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, Persistencia.compartida.contexto)
                .environmentObject(almacen)
                .environmentObject(ubicacion)
                .tint(tema.color)
                .preferredColorScheme(apariencia.esquema)
        }
    }
}

struct ContentView: View {
    var body: some View {
        TabView {
            CamaraView()
                .tabItem { Label("Cámara", systemImage: "camera") }
            GrabadoraView()
                .tabItem { Label("Grabadora", systemImage: "mic") }
            GaleriaView()
                .tabItem { Label("Galería", systemImage: "photo.on.rectangle.angled") }
            AjustesView()
                .tabItem { Label("Ajustes", systemImage: "gearshape") }
        }
    }
}

/// Tema, apariencia e información de almacenamiento.
struct AjustesView: View {
    @EnvironmentObject private var almacen: Almacen
    @AppStorage("tema") private var tema: TemaApp = .guinda
    @AppStorage("apariencia") private var apariencia: Apariencia = .sistema
    @FetchRequest(sortDescriptors: []) private var capturas: FetchedResults<Captura>

    var body: some View {
        NavigationStack {
            Form {
                Section("Tema") {
                    Picker("Tema", selection: $tema) {
                        ForEach(TemaApp.allCases) { t in
                            Label { Text(t.nombre) } icon: { Circle().fill(t.color).frame(width: 22, height: 22) }
                                .tag(t)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                Section {
                    Picker("Apariencia", selection: $apariencia) {
                        ForEach(Apariencia.allCases) { Text($0.nombre).tag($0) }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Apariencia")
                } footer: {
                    Text("«Sistema» sigue el modo claro u oscuro de iOS.")
                }
                Section {
                    LabeledContent("Fotos", value: "\(capturas.filter { $0.tipoCaptura == .foto }.count)")
                    LabeledContent("Grabaciones", value: "\(capturas.filter { $0.tipoCaptura == .audio }.count)")
                    Label("Sin conexión: todo se guarda en el dispositivo.", systemImage: "icloud.slash")
                } header: {
                    Text("Almacenamiento")
                } footer: {
                    Text("Las capturas se pueden ver y exportar desde la app Archivos › En mi iPhone › Cámara P3 › Capturas.")
                }
                Section("Acerca de") {
                    LabeledContent("App", value: "Cámara P3 1.0")
                    LabeledContent("Práctica", value: "3 · ESCOM-IPN")
                }
            }
            .navigationTitle("Ajustes")
        }
    }
}
