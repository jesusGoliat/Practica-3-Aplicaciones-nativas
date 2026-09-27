# Ejercicio 4 — Cámara y micrófono con Flutter (Opción B)

App multiplataforma (Android + iOS) para tomar fotos con filtros, flash y
temporizador, grabar audio con sensibilidad y límite de tiempo, y organizar
todo en una galería con álbumes y etiquetas. Funciona **sin Internet**.

## Versiones fijadas

| Herramienta | Versión | Motivo |
|---|---|---|
| Flutter / Dart | **3.24.0** / 3.5.0 | Versión con la que se desarrolló y probó |
| AGP / Gradle / Kotlin | 8.7.2 / 8.9 / 2.0.21 | La plantilla de `flutter create` (AGP 7.3) no compila con JDK 21 (LECCIONES §5) |
| iOS mínimo | 14.0 | Requisito de `camera_avfoundation` y `share_plus` |
| Android mínimo | API 24 | Requisito de `camera`, `record` y `permission_handler` |

`record_android` y `record_platform_interface` están fijados con
`dependency_overrides`, porque las versiones nuevas usan propiedades de Gradle
que Flutter 3.24 no tiene. El comentario del `pubspec.yaml` explica el detalle.

## Arquitectura (Clean Architecture + Provider)

```text
lib/
├── main.dart                 Arranque: abre SQLite, SharedPreferences y el directorio de la app
├── app.dart                  MaterialApp (M3, es-MX, temas) y barra de navegación
├── core/
│   ├── inyeccion.dart        Composición de dependencias (único lugar que conoce las 3 capas)
│   └── theme/tema_app.dart   Paletas Guinda IPN / Azul ESCOM, claro y oscuro
├── domain/                   Sin dependencias de Flutter ni de plugins
│   ├── entities/             ElementoMultimedia, FiltroFoto (matrices de color)
│   ├── repositories/         Contrato RepositorioMultimedia
│   └── usecases/             GuardarFoto, GuardarAudio, EditarFoto, ImportarArchivo, …
├── data/
│   ├── datasources/          BaseDatosLocal (sqflite), AlmacenArchivos (fotos, audios, miniaturas), Preferencias
│   ├── models/               Conversión entidad ↔ fila SQL
│   └── repositories/         RepositorioMultimediaImpl
└── presentation/
    ├── providers/            EstadoAjustes, EstadoGaleria (ChangeNotifier)
    ├── screens/              Cámara, Audio, Galería, Foto (visor + editor), Reproductor, Ajustes
    └── widgets/              Permisos, hoja de metadatos, diálogos
```

- **Dominio**: define qué hace la app (casos de uso) sin saber cómo se guarda.
- **Datos**: SQLite guarda los metadatos (tipo, fecha, álbum, etiquetas, filtro
  y duración). Los archivos van al directorio de documentos de la app, y cada
  foto tiene una miniatura de 320 px para que la galería cargue rápido.
- **Presentación**: Provider + ChangeNotifier. Las pantallas solo llaman a los
  casos de uso.
- El procesamiento de imágenes (filtro, giro y miniatura) corre en un
  `Isolate` para no congelar la interfaz.

## Plugins y justificación

| Plugin | Versión | Uso | Por qué este |
|---|---|---|---|
| `camera` | 0.11.0+2 | Vista previa, flash y captura | Plugin oficial del equipo de Flutter; usa CameraX y AVFoundation |
| `record` | 5.1.2 | Grabación AAC con medidor de amplitud | Permite configurar ganancia, supresión de ruido y frecuencia, y expone el nivel en tiempo real |
| `audioplayers` | 6.4.0 | Reproductor | API sencilla con posición, duración y búsqueda |
| `image_picker` | 1.1.2 | Fototeca como fuente alternativa (simulador iOS) | Oficial; en iOS usa PHPicker |
| `file_picker` | 8.3.7 | Importar fotos y audios desde Archivos | Selector del sistema en ambas plataformas |
| `permission_handler` | 11.4.0 | Permisos de cámara y micrófono en tiempo de ejecución | Una sola API para los dos sistemas, con estado "negado permanentemente" |
| `sqflite` | 2.4.1 | Metadatos | SQLite multiplataforma; permite consultas por álbum y tipo |
| `shared_preferences` | 2.x | Tema, modo, sensibilidad, límite | Clave/valor simple (UserDefaults / SharedPreferences) |
| `path_provider` / `path` | 2.1 / 1.9 | Directorio de documentos de la app | Estándar |
| `image` | 4.x | Filtros, giro y miniaturas en Dart puro | Aplica al archivo la misma matriz que se ve en la vista previa |
| `share_plus` | 10.1.4 | Exportar (hoja de compartir) | Oficial de la comunidad Flutter |
| `provider` | 6.1.5 | Gestión de estado | Es el más simple de los que acepta la práctica y basta para dos estados globales |

## Funcionalidades

- **Fotos:** 6 filtros (vista previa en vivo con `ColorFiltered`), flash
  (apagado / auto / siempre / linterna), temporizador de 3, 5 o 10 s con
  cuenta regresiva animada, y cambio entre cámara frontal y trasera.
- **Sin cámara** (simulador de iOS): la app lo detecta y muestra
  «Elegir de la fototeca». El filtro elegido se aplica igual.
- **Audio:** sensibilidad baja / media / alta (ganancia automática, supresión
  de ruido y calidad), temporizador de 15, 30 o 60 s que se detiene solo,
  pausa, medidor animado e historial de onda.
- **Galería:** fotos en cuadrícula con miniaturas en caché, audios en lista
  con «deslizar para eliminar», álbumes, etiquetas, editor (girar y filtro),
  reproductor, exportar e importar.
- **Temas:** Guinda IPN y Azul ESCOM. Por defecto siguen el modo claro u
  oscuro del sistema, y en Ajustes se puede forzar uno.

## Cómo ejecutar

### Android (Linux o Windows)
```bash
flutter pub get
flutter test                     # 10 pruebas (repositorio + interfaz)
flutter run                      # con el celular conectado por USB
flutter build apk --release      # → build/app/outputs/flutter-apk/app-release.apk
```

### iOS (solo en macOS)
Ver `INSTRUCTIVO_MACOS.md`, paso 8. Resumen:
```bash
flutter pub get
cd ios && pod install && cd ..
flutter run -d "iPhone 15"
```

## Pruebas automáticas (sin dispositivo)

- `test/repositorio_test.dart`: guardar foto con filtro, girar, álbumes y
  etiquetas, eliminar, rechazar archivos dañados o no soportados, e importar
  audio (SQLite en memoria vía FFI).
- `test/widget_test.dart`: galería vacía, cambio de tema a Azul ESCOM, barra
  de navegación y temas oscuros.

Estas pruebas encontraron un bug real antes de la entrega: los audios
importados no se copiaban si venían de una carpeta dentro de la app. Se
corrigió con `AlmacenArchivos.esAudioPropio`.
