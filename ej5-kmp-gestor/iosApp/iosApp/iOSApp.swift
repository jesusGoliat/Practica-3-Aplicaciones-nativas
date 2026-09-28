import SwiftUI

/// Punto de entrada iOS. Toda la interfaz y la lógica vienen del módulo
/// compartido de Kotlin (framework ComposeApp).
@main
struct iOSApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
