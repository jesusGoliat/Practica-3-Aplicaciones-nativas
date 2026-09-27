# Checklist final antes de entregar (lunes 28 de septiembre de 2026)

Márcalo en orden. Lo verifica Jesús con el resto del equipo en la llamada final.

## Portada y datos
- [ ] `README.md`: los 4 nombres completos y boletas, asignatura, profesor, grupo y fecha
- [ ] No queda ningún marcador pendiente: `grep -rn "«" --include=*.md .` no debe mostrar nada
- [ ] Correos y nombres de los autores de los commits correctos (`git shortlog -sne`)

## Ejercicio 1: entorno macOS
- [ ] `comparativa-pcs.md` con las 4 filas llenas y la justificación de la PC elegida
- [ ] Se indica que nadie tiene Mac física (o quién y qué modelo)
- [ ] `guia-instalacion.md` con capturas 01–08 y las observaciones llenas
- [ ] `bitacora.md`: cada sesión con fecha, hora de inicio y fin, modalidad, presentes y actividades
- [ ] Evidencia de cada reunión (`img/09-reunion-NN.png`)
- [ ] Responsable del equipo y justificación registrados

## Ejercicio 2: Gestor de archivos iOS (comparar con el PDF 2.1–2.5)
- [ ] Explora Documents, Inbox y tmp · íconos por UTType · visor de texto
- [ ] Imagen con pellizcar, rotar y ajustar · Quick Look
- [ ] Crear carpeta, copiar, mover, renombrar, eliminar con confirmación
- [ ] Importar con UIDocumentPicker · compartir con UIActivityViewController
- [ ] Guinda/Azul en claro/oscuro · NavigationStack con ruta visible · búsqueda y orden
- [ ] Deslizar para eliminar · menú contextual · deslizar para actualizar · horizontal
- [ ] Recientes · favoritos · caché de miniaturas · preferencias de sesión
- [ ] Security-scoped bookmarks · manejo de errores · `UIFileSharingEnabled` y `LSSupportsOpeningDocumentsInPlace`
- [ ] Capturas 01–20 en `ej2-gestor-ios/img/` · `GestorArchivos-ios-simulador.zip`
- [ ] (Opcional) Mac Catalyst: captura + diferencias de interfaz documentadas

## Ejercicio 3: Cámara y micrófono iOS (comparar con el PDF 3.1–3.6)
- [ ] Informe dice **qué fuente se usó**: simulador + PHPicker
- [ ] AVCaptureSession · AVAudioRecorder · filtros, flash, temporizador · sensibilidad y temporizador de audio
- [ ] Permisos en Info.plist y solicitados en tiempo de ejecución (capturas 01 y 02)
- [ ] Galería con edición · reproductor · álbumes
- [ ] Core Data con fecha, ubicación y etiquetas · miniaturas · exportar e importar
- [ ] Capturas 01–15 · `CamaraMic-ios-simulador.zip`

## Ejercicio 4: Flutter
- [ ] `flutter analyze` sin problemas y `flutter test` en verde
- [ ] APK en `binarios/` instalado y probado en un celular real
- [ ] Capturas `android-*` e `ios-*`
- [ ] README con plugins, justificación y arquitectura

## Ejercicio 5: Kotlin Multiplatform
- [ ] `./gradlew :composeApp:testDebugUnitTest` en verde · APK en `binarios/`
- [ ] App iOS compilada desde Xcode en la VM · capturas `android-*` e `ios-*` · `estructura-proyecto.png`
- [ ] README con estructura, tabla expect/actual y librerías
- [ ] Tabla comparativa 5.5 con los datos medidos en la VM (tamaños y tiempos) y conclusión

## Informe (README.md)
- [ ] Introducción · desarrollo con capturas de cada ejercicio · pruebas realizadas
- [ ] Bitácora · conclusiones **en primera persona de los 4** · referencias en APA
- [ ] Todas las imágenes enlazadas existen: 
      `grep -oE '\(([^)]+\.png)\)' README.md */*.md | sed -E 's/.*\((.*)\)/\1/' | while read f; do [ -f "$f" ] || [ -f "ej1-entorno/$f" ] || echo "FALTA $f"; done`
- [ ] Sección «Problemas conocidos» con lo que no se alcanzó a corregir

## Reglas del repositorio (LECCIONES_APRENDIDAS)
- [ ] Los 4 integrantes con un número similar de commits (`git shortlog -sne`)
- [ ] Ningún commit con `Co-Authored-By` (`git log --format=%B | grep -i co-authored` vacío)
- [ ] No se subieron el PDF, `LECCIONES_APRENDIDAS.md`, `build/`, `.xcodeproj` generados ni `local.properties` (`git ls-files | grep -Ei "pdf|lecciones|/build/|local.properties"` vacío, salvo PDFs de ejemplo de las apps)
- [ ] **No se cambió la interfaz después de tomar las capturas**
- [ ] Nombres de capturas `NN-descripcion.png` (nada de `WhatsApp Image…`)
- [ ] Todas las apps funcionan en modo avión

## Entrega
- [ ] `git push` final y verificar el repositorio en GitHub (README se ve bien, imágenes cargan)
- [ ] Liga del repositorio + binarios + informe entregados antes de la fecha límite
