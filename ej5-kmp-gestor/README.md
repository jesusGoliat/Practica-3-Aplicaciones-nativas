# Ejercicio 5 — Gestor de archivos con Kotlin Multiplatform (Opción A)

Gestor de archivos para Android e iOS que comparte la lógica de negocio **y la
interfaz** (Compose Multiplatform) en `commonMain`. Los accesos que cambian
entre plataformas usan `expect`/`actual`. Funciona **sin Internet**.

Se eligió la opción contraria a la del Ejercicio 4 (cámara en Flutter), como
sugiere la práctica.

## Versiones

| Herramienta | Versión |
|---|---|
| Kotlin | 2.0.21 |
| Compose Multiplatform | 1.7.0 |
| AGP / Gradle | 8.7.2 / 8.9 |
| Coroutines | 1.9.0 |
| SQLDelight | 2.0.2 |
| JDK | 17 o 21 |
| iOS mínimo | 16.0 (destinos `iosX64`, `iosArm64`, `iosSimulatorArm64`) |

> **iosX64 es obligatorio**: macOS en Docker corre sobre un CPU Intel
> emulado, así que el simulador es x86_64.

## Estructura del proyecto

```text
ej5-kmp-gestor/
├── settings.gradle.kts, build.gradle.kts, gradle/libs.versions.toml
├── composeApp/
│   ├── build.gradle.kts                 Destinos Android + iOS, SQLDelight, recursos
│   └── src/
│       ├── commonMain/                  ≈ 78 % del código
│       │   ├── kotlin/…/App.kt          Navegación (Archivos, Favoritos, Recientes, Ajustes)
│       │   ├── kotlin/…/dominio/        Modelos, ordenar, filtrar, validar nombres (lógica pura)
│       │   ├── kotlin/…/datos/          RepositorioGestor (SQLDelight + Flow), archivos de ejemplo
│       │   ├── kotlin/…/plataforma/     Declaraciones expect
│       │   ├── kotlin/…/ui/             EstadoGestor (StateFlow), pantallas Compose, temas
│       │   ├── sqldelight/…/Gestor.sq   Tablas favorito, reciente, preferencia
│       │   └── composeResources/files/  Imagen de ejemplo
│       ├── androidMain/                 actual con java.io, Intent, FileProvider, SAF
│       ├── iosMain/                     actual con NSFileManager, UIKit, Skia
│       ├── commonTest/                  Pruebas de la lógica compartida
│       └── androidUnitTest/             Pruebas de SQLDelight en la JVM
└── iosApp/                              Proyecto Xcode (XcodeGen) con SwiftUI mínimo
    ├── project.yml                      Fase de compilación que llama a Gradle
    └── iosApp/{iOSApp,ContentView}.swift
```

| Conjunto de fuentes | Líneas (sin vacías) |
|---|---|
| commonMain (Kotlin + SQL) | 1 241 |
| androidMain | 135 |
| iosMain | 179 |
| iosApp (Swift) | 27 |

## Implementaciones expect / actual

| `expect` (commonMain) | Android (`actual`) | iOS (`actual`) |
|---|---|---|
| `class SistemaArchivos` | `java.io.File` en `filesDir/Documentos` y `cacheDir` | `NSFileManager` en `Documents` y `tmp` (sandbox) |
| `fun crearDriver(): SqlDriver` | `AndroidSqliteDriver` | `NativeSqliteDriver` (SQLite del sistema, `-lsqlite3`) |
| `fun formatearFecha(ms)` | `java.text.DateFormat` es-MX | `NSDateFormatter` es_MX |
| `fun decodificarImagen(bytes)` | `BitmapFactory` → `asImageBitmap()` | `org.jetbrains.skia.Image` → `toComposeImageBitmap()` |
| `fun compartirArchivo(ruta)` | `Intent.ACTION_SEND` + `FileProvider` | `UIActivityViewController` |
| `@Composable rememberImportador(…)` | Storage Access Framework (`OpenMultipleDocuments`), copia con `ContentResolver` | `UIDocumentPickerViewController` + acceso *security-scoped* |
| `@Composable ManejarAtras(…)` | `BackHandler` (botón atrás del sistema) | Sin efecto (iOS usa el botón de la barra) |
| `fun ahoraMillis()` | `System.currentTimeMillis()` | `NSDate().timeIntervalSince1970` |
| `val nombrePlataforma` | `Build.VERSION.RELEASE` | `UIDevice.systemVersion` |

**Permisos:** ninguna de las dos plataformas pide permisos de almacenamiento.
La app trabaja dentro de su propio contenedor, y los archivos externos llegan
por el selector del sistema, que concede el acceso a cada archivo (SAF en
Android, *security-scoped URL* en iOS). Ese mecanismo está implementado con
`expect`/`actual` en `rememberImportador`.

## Asincronía y estado

- `EstadoGestor` expone `StateFlow<EstadoExplorador>`, y la UI lo lee con
  `collectAsState()`.
- Las operaciones de archivo corren en `Dispatchers.Default` dentro de
  corrutinas, así que la interfaz nunca se bloquea.
- Favoritos y recientes son `Flow` de SQLDelight (`asFlow().mapToList()`) y
  se actualizan solos cuando cambia la tabla.

## Librerías

| Librería | Uso |
|---|---|
| Compose Multiplatform (material3, icons-extended, resources) | UI compartida con Material 3 |
| kotlinx-coroutines | Asincronía y Flow |
| SQLDelight 2 (+ coroutines-extensions) | Persistencia multiplataforma con consultas SQL verificadas al compilar |
| androidx.activity-compose | Integración con la Activity y el selector SAF |

## Funcionalidades

- Raíces **Documentos** y **Temporales**; ruta visible como migas
  (`Documentos › Imágenes`).
- Búsqueda en la carpeta y orden por nombre, fecha o tamaño; al repetir el
  criterio se invierte la dirección.
- Crear carpeta, renombrar, copiar o mover (con «Pegar aquí»), eliminar con
  confirmación, compartir e importar.
- Gestos: mantener presionado para el menú contextual, deslizar a la
  izquierda para eliminar y deslizar hacia abajo para actualizar.
- Visor de texto, visor de imagen (pellizcar, girar, doble toque) y avisos
  para archivos binarios, dañados o no soportados.
- Favoritos y recientes persistentes. Se actualizan al renombrar o mover y se
  borran al eliminar.
- Preferencias guardadas: última carpeta, orden, dirección y tema.
- Temas Guinda IPN y Azul ESCOM que siguen el modo claro u oscuro del sistema.

## Cómo compilar

### Android (Linux)
```bash
./gradlew :composeApp:testDebugUnitTest   # 13 pruebas
./gradlew :composeApp:assembleRelease     # → composeApp/build/outputs/apk/release/composeApp-release.apk
```

### iOS (macOS)
Ver `INSTRUCTIVO_MACOS.md`, paso 9. Resumen:
```bash
cd iosApp && xcodegen generate && open iosApp.xcodeproj   # ⌘R en «iPhone 15»
```
La primera compilación descarga Kotlin/Native (~1 GB) y tarda de 10 a 20
minutos en la VM.
