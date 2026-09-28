# Ejercicio 3 — Cámara y Micrófono para iPhone (Swift + SwiftUI)

Toma fotos con AVFoundation, graba audio con AVAudioRecorder y organiza todo
en una galería con álbumes. Los metadatos se guardan en Core Data. Funciona
**sin Internet**.

- **Lenguaje:** Swift 5 · **UI:** SwiftUI + UIKit · **Persistencia:** Core Data
- **Cámara:** AVCaptureSession + AVCapturePhotoOutput · **Audio:** AVAudioRecorder / AVAudioPlayer
- **Destino:** iOS 16.0+ · **Xcode:** 15.2 o superior

## Fuente de imágenes usada (requisito 3.2)

**Ningún integrante tiene iPhone**, así que la app se probó en el
**simulador**, que no tiene cámara física. Se implementaron las dos opciones:

1. **Cámara real:** el código de `AVCaptureSession` está completo (vista
   previa, flash, temporizador, cambio de cámara). Se activa solo cuando
   `AVCaptureDevice.default(for: .video)` existe.
2. **Fuente alternativa, la que se usó en las pruebas:** en el simulador la
   app lo detecta y muestra «Este dispositivo no tiene cámara» con el botón
   **«Elegir de la fototeca»** (`PHPickerViewController`). La foto elegida
   pasa por la misma pantalla de revisión, con filtros y guardado en Core
   Data.

La fototeca del simulador se llena con `xcrun simctl addmedia booted muestras/*.png`
(ver el instructivo).

## Estructura

```text
ej3-camara-ios/
├── project.yml                    XcodeGen + permisos en Info.plist
├── muestras/                      Fotos y audio de prueba para el simulador
└── CamaraMic/
    ├── App/CamaraMicApp.swift     Pestañas, Ajustes (tema/apariencia)
    ├── Camera/
    │   ├── ServicioCamara.swift   AVCaptureSession, flash, cambio de cámara, captura async
    │   ├── CamaraView.swift       Vista previa, temporizador, disparador animado, revisión con filtros
    │   ├── Filtros.swift          Filtros Core Image; girar y recortar
    │   ├── PuentesUIKit.swift     Vista previa (AVCaptureVideoPreviewLayer), PHPicker, compartir
    │   └── ServicioUbicacion.swift Ubicación opcional como metadato
    ├── Audio/
    │   ├── ServicioAudio.swift    AVAudioRecorder (medidor, sensibilidad, límite), AVAudioPlayer
    │   └── GrabadoraView.swift    Medidor animado, onda, pausa, ajustes de captura
    ├── Gallery/
    │   ├── GaleriaView.swift      Cuadrícula/lista, álbumes, importar
    │   └── DetallesView.swift     Visor con zoom, editor, reproductor, metadatos, exportar
    ├── Persistence/
    │   ├── CamaraMic.xcdatamodeld Entidades Captura y Album
    │   ├── Persistencia.swift     NSPersistentContainer
    │   └── Almacen.swift          Archivos + Core Data + miniaturas (disco y NSCache)
    └── Theme/Tema.swift           Guinda IPN / Azul ESCOM
```

## Modelo de Core Data

| Entidad | Atributos | Relación |
|---|---|---|
| `Captura` | `id`, `tipo` (foto/audio), `archivo`, `miniatura`, `fecha`, `latitud`, `longitud`, `etiquetas`, `filtro`, `duracion` | `album` → Album (0..1) |
| `Album` | `id`, `nombre`, `fecha` | `capturas` → Captura (0..n, *Nullify*) |

## Cumplimiento de requisitos

| Requisito | Implementación |
|---|---|
| Fotos con AVCaptureSession | `ServicioCamara` |
| Audio con AVAudioRecorder | `ServicioAudio` |
| Fotos: filtros, flash, temporizador | 7 filtros Core Image; flash apagado/auto/encendido; temporizador 0/3/10 s |
| Audio: sensibilidad, temporizador | Baja/Media/Alta (ganancia de entrada si el hardware lo permite, frecuencia y umbral del medidor); límite 15/30/60 s |
| Almacenamiento de archivos | `Documents/Capturas/{fotos,audios,miniaturas}` |
| Alternativa sin cámara | PHPickerViewController (documentado arriba) |
| Info.plist y permisos en tiempo de ejecución | `NSCameraUsageDescription`, `NSMicrophoneUsageDescription` (+ fototeca y ubicación); `requestAccess` y `requestRecordPermission` |
| Visor con edición básica | Zoom con pellizco; girar, recorte cuadrado y filtro |
| Reproductor | `DetalleAudioView` con barra de avance |
| Álbumes / categorías | Entidad `Album`; filtro por álbum en la galería |
| Temas y modo claro/oscuro | `TemaApp` + `Apariencia` |
| Gestos y animaciones | Pellizcar, doble toque, disparador animado, cuenta regresiva, destello, medidor animado, deslizar para eliminar |
| Core Data para metadatos | Fecha, ubicación, etiquetas, filtro, álbum |
| Miniaturas y caché | Miniatura JPEG de 300 px al guardar + `NSCache` |
| Exportar e importar | Hoja de compartir; fototeca y app Archivos (`fileImporter`); carpeta visible en Archivos |

## Compilar y ejecutar (macOS)

```bash
cd ej3-camara-ios
xcodegen generate
open CamaraMic.xcodeproj            # esquema CamaraMic → iPhone 15 → ⌘R
xcrun simctl addmedia booted muestras/*.png
```

**Micrófono en la VM:** el simulador usa el micrófono del Mac. En macOS
virtualizado con Docker puede no haber entrada de audio: la grabación
funciona, pero queda en silencio. Para demostrar el reproductor se importa
`muestras/tono-440hz.wav` desde Galería › Importar › Archivos. Esta
limitación está documentada en el informe.
