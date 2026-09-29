# Reparto de tareas y commits (4 integrantes)

La práctica pide que **el historial de commits refleje la participación de
todos**. El código ya está hecho y probado; cada integrante sube **su parte**
con **su propia cuenta**, en commits pequeños y con sentido. Son unos 12 a 14
commits por persona.

| Integrante | Rol | Parte principal |
|---|---|---|
| 1. Jesús Ángel González Arellano (2022630690) | Base del repo, Flutter, comparativa | Ej. 4 completo + CI + tabla Flutter vs KMP |
| 2. David Alexis Hernandez Gonzalez (2024630227, `Alexis177`) | **Responsable del entorno macOS** | Ej. 1 + todas las capturas y binarios iOS |
| 3. Javier de Jesus Gamez Rosas (2022630007, `Javier-Gamez`) | iOS nativo | Ej. 2 completo + cámara del Ej. 3 |
| 4. Luis Angel Agustin Fuentes (2024630134, `luisAgt`) | iOS nativo + KMP | Ej. 3 (persistencia, audio, galería) + Ej. 5 completo |
| **Todos** | | Su fila en `comparativa-pcs.md`, sus sesiones en `bitacora.md` y su conclusión en el README |

---

## Reglas (LECCIONES_APRENDIDAS §1)

1. Antes del primer commit, configura **tu** identidad:
   ```bash
   git config --global user.name  "Tu Nombre"
   git config --global user.email "tu-correo-de-github@ejemplo.com"
   ```
2. Antes de cada commit: `git status` y `git diff --cached --stat`.
3. **Sin** líneas `Co-Authored-By` (tampoco de asistentes de IA).
4. Antes de `git push`: `git pull --rebase`. Como cada quien toca archivos
   distintos, no debería haber conflictos.
5. No subas el PDF, `LECCIONES_APRENDIDAS.md`, `build/` ni los `.xcodeproj`
   generados. El `.gitignore` ya los excluye.

## Cómo obtener los archivos

Jesús comparte **`Practica3-paquete.zip`** (todo el trabajo terminado). Cada
quien lo descomprime **fuera** de su clon del repositorio y copia sus archivos
con esta función (sirve en Linux, macOS y Git Bash de Windows):

```bash
P=~/p3-paquete                       # carpeta donde descomprimiste el zip
cd ~/Practica3                       # tu clon del repositorio
traer() { for f in "$@"; do
  if [ -d "$P/$f" ]; then mkdir -p "$f" && cp -R "$P/$f/." "$f/";
  else mkdir -p "$(dirname "$f")" && cp "$P/$f" "$f"; fi; done; }
```

Luego, para cada commit de tu tabla: `traer <rutas>` → `git add <rutas>` →
`git commit -m "<mensaje>"`.

## Orden de las rondas

| Ronda | Cuándo | Quién |
|---|---|---|
| 1 | Viernes 25 / sábado 26 temprano | ✅ Repo creado: https://github.com/jesusGoliat/Practica-3-Aplicaciones-nativas (commits 1.1–1.2 subidos). Invitados: `Javier-Gamez`, `Alexis177` y `luisAgt` |
| 2 | Sábado 26, **antes de la sesión macOS** | Integrantes 1, 3 y 4 suben su código (pueden hacerlo al mismo tiempo) |
| 3 | Sábado 26 / domingo 27, **en la sesión macOS** | Integrante 2 sube el Ej. 1, las capturas y los binarios |
| 4 | Domingo 27 / lunes 28 | Todos: bitácora, su fila de la comparativa, conclusiones; Jesús cierra el README |

---

## Integrante 1: Jesús (≈ 13 commits)

```bash
git clone https://github.com/jesusGoliat/Practica-3-Aplicaciones-nativas.git Practica3   # 1.1 y 1.2 ya están subidos
```

| # | Archivos (`traer …` y luego `git add …`) | Mensaje |
|---|---|---|
| 1.1 | `.gitignore` `binarios/.gitkeep` | `chore: estructura base y .gitignore` |
| 1.2 | `.github/workflows/ios-build.yml` | `ci: compilación iOS en runner macOS` |
| 1.3 | `ej4-flutter-camara/pubspec.yaml` `ej4-flutter-camara/pubspec.lock` `ej4-flutter-camara/analysis_options.yaml` `ej4-flutter-camara/.gitignore` `ej4-flutter-camara/.metadata` `ej4-flutter-camara/android` `ej4-flutter-camara/ios` | `feat(ej4): proyecto Flutter con versiones fijadas y permisos` |
| 1.4 | `ej4-flutter-camara/lib/domain` | `feat(ej4): capa de dominio (entidades, repositorio, casos de uso)` |
| 1.5 | `ej4-flutter-camara/lib/data` | `feat(ej4): capa de datos con sqflite y archivos locales` |
| 1.6 | `ej4-flutter-camara/lib/core` `ej4-flutter-camara/lib/presentation/providers` | `feat(ej4): temas Guinda/Azul, inyección y estado con Provider` |
| 1.7 | `ej4-flutter-camara/lib/presentation/widgets` `ej4-flutter-camara/lib/presentation/screens/pantalla_camara.dart` | `feat(ej4): cámara con filtros, flash, temporizador y fototeca` |
| 1.8 | `ej4-flutter-camara/lib/presentation/screens/pantalla_audio.dart` | `feat(ej4): grabadora con sensibilidad y temporizador` |
| 1.9 | `ej4-flutter-camara/lib/presentation/screens` `ej4-flutter-camara/lib/app.dart` `ej4-flutter-camara/lib/main.dart` | `feat(ej4): galería, visor, editor, reproductor y ajustes` |
| 1.10 | `ej4-flutter-camara/test` | `test(ej4): pruebas de repositorio e interfaz` |
| 1.11 | `ej4-flutter-camara/README.md` `binarios/ej4-flutter-camara-android.apk` | `docs(ej4): documentación de plugins y APK` |
| 1.12 | `ej4-flutter-camara/img/android-*.png` (capturas del celular) | `docs(ej4): capturas en Android` |
| 1.13 | `README.md` `REPARTO_COMMITS.md` | `docs: informe y comparativa Flutter vs KMP` |

Capturas de Android (celular por USB):
`adb exec-out screencap -p > ej4-flutter-camara/img/android-01-camara.png`
(nombres: `android-01-camara`, `android-02-filtro`, `android-03-grabadora`,
`android-04-galeria`, `android-05-visor-editor`, `android-06-reproductor`,
`android-07-ajustes-azul-oscuro`, `android-08-guinda-claro`). Haz lo mismo
con el APK del Ej. 5 (`ej5-kmp-gestor/img/`: `android-01-documentos`,
`android-02-subcarpeta-migas`, `android-03-menu-contextual`, `android-04-visor-imagen`,
`android-05-visor-texto`, `android-06-favoritos`, `android-07-azul-oscuro`, `android-08-importar`) y entrégaselas al
Integrante 4 para su commit 4.12.

## Integrante 2: responsable del entorno macOS (≈ 12 commits)

| # | Archivos | Mensaje |
|---|---|---|
| 2.1 | `ej1-entorno/comparativa-pcs.md` (con su fila y la justificación) | `docs(ej1): comparativa de PCs y elección del equipo` |
| 2.2 | `ej1-entorno/HolaMundo` | `feat(ej1): proyecto SwiftUI de prueba` |
| 2.3 | `ej1-entorno/guia-instalacion.md` `ej1-entorno/img/01-*.png` … `04-*.png` | `docs(ej1): instalación de macOS con MacOS-Docker` |
| 2.4 | `ej1-entorno/img/05-*.png` … `08-*.png` | `docs(ej1): Xcode, simuladores y herramientas` |
| 2.5 | `INSTRUCTIVO_MACOS.md` (con las correcciones que surjan) | `docs: instructivo de ejecución en macOS` |
| 2.6 | `ej2-gestor-ios/img` | `docs(ej2): capturas en el simulador de iPhone` |
| 2.7 | `ej3-camara-ios/img` | `docs(ej3): capturas en el simulador de iPhone` |
| 2.8 | `ej4-flutter-camara/img/ios-*.png` | `docs(ej4): capturas en el simulador de iOS` |
| 2.9 | `ej5-kmp-gestor/img/ios-*.png` `ej5-kmp-gestor/img/estructura-proyecto.png` | `docs(ej5): capturas en el simulador de iOS` |
| 2.10 | `binarios/*-ios-simulador.zip` (Ej. 2, 3, 4, 5) | `build: binarios .app para el simulador de iPhone` |
| 2.11 | `ej1-entorno/bitacora.md` `ej1-entorno/img/09-reunion-*.png` | `docs(ej1): bitácora y evidencias de sesiones` |
| 2.12 | `README.md` (su conclusión) | `docs: conclusión de David Alexis Hernandez Gonzalez` |

> Los `.zip` de los `.app` pesan unos 10–60 MB. GitHub acepta archivos de
> hasta 100 MB.

## Integrante 3: Gestor iOS (Ej. 2) + cámara del Ej. 3 (≈ 13 commits)

| # | Archivos | Mensaje |
|---|---|---|
| 3.1 | `ej2-gestor-ios/project.yml` `ej2-gestor-ios/GestorArchivos/Resources` | `feat(ej2): proyecto XcodeGen, permisos y recurso de ejemplo` |
| 3.2 | `ej2-gestor-ios/GestorArchivos/Theme` | `feat(ej2): temas Guinda IPN y Azul ESCOM` |
| 3.3 | `ej2-gestor-ios/GestorArchivos/Models/ElementoArchivo.swift` | `feat(ej2): modelo de archivo con UTType, orden y búsqueda` |
| 3.4 | `ej2-gestor-ios/GestorArchivos/Models/Preferencias.swift` | `feat(ej2): favoritos, recientes y preferencias de sesión` |
| 3.5 | `ej2-gestor-ios/GestorArchivos/Services/ServicioArchivos.swift` | `feat(ej2): operaciones con FileManager y manejo de errores` |
| 3.6 | `ej2-gestor-ios/GestorArchivos/Services/CacheMiniaturas.swift` `ej2-gestor-ios/GestorArchivos/Services/CarpetasExternas.swift` | `feat(ej2): caché de miniaturas y security-scoped bookmarks` |
| 3.7 | `ej2-gestor-ios/GestorArchivos/Views/PuentesUIKit.swift` | `feat(ej2): UIDocumentPicker, Quick Look y hoja de compartir` |
| 3.8 | `ej2-gestor-ios/GestorArchivos/Views/ContentView.swift` `ej2-gestor-ios/GestorArchivos/Views/ExploradorView.swift` `ej2-gestor-ios/GestorArchivos/Views/CarpetaView.swift` `ej2-gestor-ios/GestorArchivos/Views/SelectorDestinoView.swift` | `feat(ej2): explorador con NavigationStack, gestos y operaciones` |
| 3.9 | `ej2-gestor-ios/GestorArchivos/Views/VisoresView.swift` `ej2-gestor-ios/GestorArchivos/Views/MarcadoresView.swift` `ej2-gestor-ios/GestorArchivos/Views/AjustesView.swift` `ej2-gestor-ios/GestorArchivos/App` | `feat(ej2): visores, favoritos, recientes y ajustes` |
| 3.10 | `ej2-gestor-ios/README.md` | `docs(ej2): documentación del gestor de archivos` |
| 3.11 | `ej3-camara-ios/CamaraMic/Camera/Filtros.swift` `ej3-camara-ios/CamaraMic/Camera/ServicioCamara.swift` `ej3-camara-ios/CamaraMic/Camera/ServicioUbicacion.swift` | `feat(ej3): servicio de cámara AVFoundation y filtros Core Image` |
| 3.12 | `ej3-camara-ios/CamaraMic/Camera/PuentesUIKit.swift` `ej3-camara-ios/CamaraMic/Camera/CamaraView.swift` | `feat(ej3): pantalla de cámara con fototeca como alternativa` |
| 3.13 | `ej1-entorno/comparativa-pcs.md` (su fila) + `README.md` (su conclusión) | `docs: datos de equipo y conclusión de Javier de Jesus Gamez Rosas` |

## Integrante 4: Ej. 3 (persistencia, audio, galería) + KMP (Ej. 5) (≈ 13 commits)

| # | Archivos | Mensaje |
|---|---|---|
| 4.1 | `ej3-camara-ios/project.yml` `ej3-camara-ios/CamaraMic/Theme` `ej3-camara-ios/muestras` | `feat(ej3): proyecto XcodeGen, permisos y muestras para el simulador` |
| 4.2 | `ej3-camara-ios/CamaraMic/Persistence` | `feat(ej3): modelo Core Data y almacén de capturas` |
| 4.3 | `ej3-camara-ios/CamaraMic/Audio` | `feat(ej3): grabación con AVAudioRecorder y reproductor` |
| 4.4 | `ej3-camara-ios/CamaraMic/Gallery` `ej3-camara-ios/CamaraMic/App` `ej3-camara-ios/README.md` | `feat(ej3): galería con álbumes, editor y exportación` |
| 4.5 | `ej5-kmp-gestor/settings.gradle.kts` `ej5-kmp-gestor/build.gradle.kts` `ej5-kmp-gestor/gradle.properties` `ej5-kmp-gestor/gradle` `ej5-kmp-gestor/gradlew` `ej5-kmp-gestor/gradlew.bat` `ej5-kmp-gestor/.gitignore` `ej5-kmp-gestor/composeApp/build.gradle.kts` | `feat(ej5): proyecto Kotlin Multiplatform con Compose Multiplatform` |
| 4.6 | `ej5-kmp-gestor/composeApp/src/commonMain/kotlin/mx/ipn/escom/p3/gestor/dominio` `ej5-kmp-gestor/composeApp/src/commonTest` | `feat(ej5): lógica de dominio compartida y pruebas` |
| 4.7 | `ej5-kmp-gestor/composeApp/src/commonMain/sqldelight` `ej5-kmp-gestor/composeApp/src/commonMain/kotlin/mx/ipn/escom/p3/gestor/datos` `ej5-kmp-gestor/composeApp/src/commonMain/composeResources` `ej5-kmp-gestor/composeApp/src/androidUnitTest` | `feat(ej5): persistencia con SQLDelight y Flow` |
| 4.8 | `ej5-kmp-gestor/composeApp/src/commonMain/kotlin/mx/ipn/escom/p3/gestor/plataforma` | `feat(ej5): declaraciones expect de plataforma` |
| 4.9 | `ej5-kmp-gestor/composeApp/src/commonMain/kotlin/mx/ipn/escom/p3/gestor/ui` `ej5-kmp-gestor/composeApp/src/commonMain/kotlin/mx/ipn/escom/p3/gestor/App.kt` | `feat(ej5): interfaz compartida y estado con StateFlow` |
| 4.10 | `ej5-kmp-gestor/composeApp/src/androidMain` | `feat(ej5): implementaciones actual para Android` |
| 4.11 | `ej5-kmp-gestor/composeApp/src/iosMain` `ej5-kmp-gestor/iosApp` | `feat(ej5): implementaciones actual para iOS y app Xcode` |
| 4.12 | `ej5-kmp-gestor/README.md` `binarios/ej5-kmp-gestor-android.apk` `ej5-kmp-gestor/img/android-*.png` | `docs(ej5): estructura, expect/actual y APK` |
| 4.13 | `ej1-entorno/comparativa-pcs.md` (su fila) + `README.md` (su conclusión) | `docs: datos de equipo y conclusión de Luis Angel Agustin Fuentes` |

---

## Verificación final (la hace Jesús el lunes 28)

```bash
git shortlog -sne                         # los 4 con un número similar de commits
git log --format='%an <%ae>%n%B' | grep -i "co-authored" || echo "OK: sin coautores"
```
