# Ejercicio 2 — Gestor de Archivos para iPhone (Swift + SwiftUI)

Gestor de archivos nativo que explora el sandbox de la app (Documents, Inbox
y tmp) y las carpetas externas que el usuario autorice. Funciona **sin
Internet**.

- **Lenguaje:** Swift 5 · **UI:** SwiftUI con puentes a UIKit · **Persistencia:** UserDefaults
- **Destino:** iOS 16.0+ (iPhone; iPad opcional) · **Xcode:** 15.2 o superior
- **Opcional (valor agregado):** el target tiene `SUPPORTS_MACCATALYST: YES`,
  así que también compila para macOS con Mac Catalyst.

## Estructura

```text
ej2-gestor-ios/
├── project.yml                     Definición del proyecto (XcodeGen) + claves de Info.plist
└── GestorArchivos/
    ├── App/GestorArchivosApp.swift Punto de entrada; crea carpetas y archivos de ejemplo
    ├── Models/
    │   ├── ElementoArchivo.swift   Archivo/carpeta, categoría por UTType, ordenar y filtrar
    │   └── Preferencias.swift      Tema, apariencia, orden, última carpeta, favoritos, recientes
    ├── Services/
    │   ├── ServicioArchivos.swift  FileManager: listar, crear, copiar, mover, renombrar, eliminar, importar
    │   ├── CacheMiniaturas.swift   QLThumbnailGenerator + NSCache + disco (Library/Caches)
    │   └── CarpetasExternas.swift  Security-scoped bookmarks
    ├── Theme/Tema.swift            Guinda IPN / Azul ESCOM con variante clara y oscura
    ├── Views/
    │   ├── ContentView.swift       Pestañas, filas, miniaturas, apertura de archivos
    │   ├── ExploradorView.swift    Ubicaciones + restauración de la última carpeta
    │   ├── CarpetaView.swift       Lista, búsqueda, orden, gestos, menú contextual, operaciones
    │   ├── VisoresView.swift       Texto; imagen con pellizcar, rotar y ajustar
    │   ├── PuentesUIKit.swift      UIDocumentPicker, QLPreviewController, UIActivityViewController
    │   ├── SelectorDestinoView.swift Destino para copiar o mover
    │   ├── MarcadoresView.swift    Favoritos y Recientes
    │   └── AjustesView.swift       Tema, apariencia, orden, caché
    └── Resources/muestra.png       Imagen de ejemplo
```

## Cumplimiento de requisitos

| Requisito del PDF | Dónde |
|---|---|
| 2.1 Explorar Documents, Inbox, tmp con FileManager | `ServicioArchivos.raices`, `listar` |
| 2.1 Íconos según UTType | `ElementoArchivo.categoria` / `Categoria.icono` |
| 2.1 Visor de texto (.txt, .md, .swift, .json…) | `VisorTextoView` |
| 2.1 Imágenes con pellizcar, rotar y ajustar | `VisorImagenView` (MagnificationGesture + RotationGesture, doble toque) |
| 2.1 Quick Look | `VistaQuickLook` (QLPreviewController), PDF y otros tipos |
| 2.1 Crear, copiar, mover, renombrar, eliminar con confirmación | `CarpetaView` + `ServicioArchivos` |
| 2.1 Importar con UIDocumentPickerViewController | `SelectorDocumentos` («Importar desde Archivos») |
| 2.1 Compartir con UIActivityViewController | `HojaCompartir` |
| 2.2 Temas Guinda/Azul, claro y oscuro | `TemaApp` (UIColor dinámico) |
| 2.2 NavigationStack con la ruta visible | `ExploradorView` + `RutaView` en el encabezado |
| 2.2 Búsqueda y orden por nombre, fecha o tamaño | `.searchable`, menú «Opciones» |
| 2.2 Deslizar para eliminar, menú contextual, deslizar para actualizar | `.swipeActions`, `.contextMenu`, `.refreshable` |
| 2.2 Vertical y horizontal | `UISupportedInterfaceOrientations` en `project.yml` |
| 2.3 Recientes y favoritos persistentes | `Preferencias` (UserDefaults, rutas relativas al contenedor) |
| 2.3 Caché de miniaturas | `CacheMiniaturas` (memoria + disco) |
| 2.3 Preferencias de sesión | Última carpeta, orden y tema en `Preferencias` |
| 2.4 Respetar el sandbox | Solo raíces del contenedor; `estaEnSandbox` |
| 2.4 Security-scoped bookmarks | `CarpetasExternas.agregar/abrir` |
| 2.4 Errores: inaccesible, dañado, no soportado | `ErrorArchivo`; ejemplos `dañada.jpg` y `datos.xyz` |
| 2.4 `UIFileSharingEnabled`, `LSSupportsOpeningDocumentsInPlace` | `project.yml` → Info.plist |

## Archivos de ejemplo (primer arranque)

`Bienvenida.txt`, `Notas.md`, `config.json`, `Reporte.pdf` (generado en el
dispositivo), `Proyectos/2026/Ejemplo.swift`, `Imágenes/escom.png`,
`Imágenes/dañada.jpg` (para probar errores), `datos.xyz` (tipo no soportado)
y `tmp/cache.txt`.

## Compilar y ejecutar (macOS)

```bash
cd ej2-gestor-ios
xcodegen generate
open GestorArchivos.xcodeproj      # esquema GestorArchivos → iPhone 15 → ⌘R
```
Para el paso a paso, los resultados esperados y las capturas, ver
`INSTRUCTIVO_MACOS.md`.
