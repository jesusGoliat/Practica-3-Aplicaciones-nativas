import SwiftUI

/// Proyecto mínimo para comprobar que Xcode, el SDK de iOS y el simulador
/// funcionan en el entorno macOS (Ejercicio 1.4).
@main
struct HolaMundoApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

struct ContentView: View {
    @State private var toques = 0

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "swift")
                .font(.system(size: 80))
                .foregroundStyle(Color(red: 0x6C / 255, green: 0x1D / 255, blue: 0x45 / 255))
            Text("¡Hola, ESCOM!")
                .font(.largeTitle.bold())
            Text("Entorno macOS + Xcode funcionando")
                .foregroundStyle(.secondary)
            Text(UIDevice.current.name + " · iOS " + UIDevice.current.systemVersion)
                .font(.footnote.monospaced())
            Button("Toques: \(toques)") { toques += 1 }
                .buttonStyle(.borderedProminent)
                .tint(Color(red: 0, green: 0x3B / 255, blue: 0x5C / 255))
        }
        .padding()
    }
}
