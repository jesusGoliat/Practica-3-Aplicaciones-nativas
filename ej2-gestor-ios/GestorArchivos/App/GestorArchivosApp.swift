import SwiftUI

/// Punto de entrada del Gestor de Archivos (Ejercicio 2).
///
/// La app trabaja solo dentro de su sandbox (Documents, Inbox y tmp) y con
/// las carpetas externas que el usuario autorice con el selector de
/// documentos. No usa red: todo se guarda en el dispositivo.
@main
struct GestorArchivosApp: App {
    @StateObject private var preferencias = Preferencias()
    @StateObject private var externas = CarpetasExternas()

    init() {
        // Crea las carpetas base y archivos de ejemplo la primera vez.
        ServicioArchivos.compartido.prepararSandbox()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(preferencias)
                .environmentObject(externas)
                .tint(preferencias.tema.color)
                .preferredColorScheme(preferencias.apariencia.esquema)
        }
    }
}
