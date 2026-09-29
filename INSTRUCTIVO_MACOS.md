# Instructivo para ejecutar la práctica en macOS (Integrante 2: David Alexis)

Este documento es para quien virtualiza macOS. El código ya está escrito, y la
parte Android está compilada y probada en Linux.

> ✅ **Estado al 28 sep 2026:** los **5 ejercicios ya compilan para iOS** con
> **Xcode 15.2** en un Mac de GitHub Actions (la misma versión que vas a
> instalar). Si algo falla en tu VM, casi seguro es del entorno (instalación,
> rutas, memoria), no del código.

Tu trabajo es:
**instalar el entorno → compilar → ejecutar en el simulador → tomar capturas →
subir tus commits**.

> ⚠️ **La práctica exige trabajo conjunto.** Haz las sesiones en videollamada
> con pantalla compartida y con los 4 integrantes. Al inicio de cada sesión
> toma una captura de la llamada (`ej1-entorno/img/09-reunion-NN.png`) y
> anota la sesión en `ej1-entorno/bitacora.md`.

**Tiempo estimado:** 3 a 5 h la instalación (casi todo es descarga) y 3 a 4 h
la compilación y las capturas.

---

## 0. Resumen de versiones

| Componente | Versión | Por qué |
|---|---|---|
| macOS (en Docker) | **Ventura 13** (`SHORTNAME=ventura`) | Es la que usa el repositorio del profesor |
| Xcode | **15.2** | Es la versión más nueva que corre en Ventura. 15.3 o superior exige Sonoma |
| Simulador | iOS 17.2 (viene con Xcode 15.2), **iPhone 15** + un iPad | Los proyectos piden iOS 16.0 o superior |
| XcodeGen | La más reciente | Genera los `.xcodeproj` a partir de `project.yml` |
| CocoaPods | 1.15 o superior | Lo necesitan los plugins de Flutter en iOS |
| Flutter | **3.24.0** (exacta) | Es la del proyecto. Con otra versión pueden fallar los plugins |
| JDK | 17 (Temurin) | Para compilar el módulo Kotlin del Ej. 5 |

---

## 1. Requisitos de la PC anfitriona

| Requisito | Mínimo (README del repositorio) | PC de Alexis |
|---|---|---|
| RAM | 16 GB | 16 GB ✅ (justo; ver `.wslconfig` en el paso 2A) |
| Disco libre | 50 GB con Xcode; **se recomiendan 120 GB** | 1.17 TB ✅ |
| Virtualización | VT-x activo + KVM dentro de WSL | Habilitada ✅ (i5-10600KF) |
| Docker | Docker Desktop (Windows) o Docker Engine (Linux) | Por instalar |

📸 `ej1-entorno/img/01-specs-pc-elegida.png`:
- **Windows:** Administrador de tareas › Rendimiento (CPU con «Virtualización:
  Habilitado», y la memoria) junto con la terminal de Ubuntu mostrando `kvm-ok`.
- **Linux:** terminal con `lscpu`, `free -h`, `df -h` y `kvm-ok`.

---

## 2. Instalar macOS con MacOS-Docker

Se basa en el README de <https://github.com/gabrielhuav/MacOS-Docker>. La
PC de Alexis tiene **Windows 11**, así que sigue el **2A**. El **2B** es para
Linux.

### 2A. Windows 11 (Docker Desktop + WSL2)

**1. Instalar WSL2 con Ubuntu.** En PowerShell **como administrador**:
```powershell
wsl --install -d Ubuntu
```
Reinicia la PC cuando lo pida. Al abrir «Ubuntu» por primera vez, crea usuario
y contraseña.

✅ `wsl -l -v` en PowerShell muestra `Ubuntu  Running  2` (el **2** es WSL2).

**2. Dar recursos a WSL y activar la virtualización anidada.** WSL usa por
defecto solo la mitad de la RAM (8 GB), y macOS no alcanzaría. En PowerShell:
```powershell
notepad "$env:USERPROFILE\.wslconfig"
```
Pega esto, guarda y cierra:
```ini
[wsl2]
nestedVirtualization=true
memory=13GB
processors=10
swap=8GB
```
Aplica los cambios con:
```powershell
wsl --shutdown
```

**3. Instalar Docker Desktop.** Descárgalo de
<https://www.docker.com/products/docker-desktop/> y deja marcado «Use WSL 2».
Luego, en **Settings › Resources › WSL Integration**, activa **«Enable
integration with my default WSL distro»** y el interruptor de **Ubuntu**, y
pulsa **Apply & restart**.

✅ En la terminal de Ubuntu, `docker run hello-world` imprime «Hello from Docker!».

**4. Verificar KVM dentro de Ubuntu (WSL):**
```bash
sudo apt update && sudo apt -y install cpu-checker
kvm-ok
```
✅ Debe responder `INFO: /dev/kvm exists` y `KVM acceleration can be used`.
Si no:
```bash
sudo apt -y install bridge-utils cpu-checker libvirt-clients libvirt-daemon qemu-system-x86 qemu-kvm
```
Si aun así falla, revisa que la virtualización (Intel VT-x) esté activa en la
BIOS.

**5. Soporte de ventanas** (Windows 11 trae WSLg, así que la ventana de QEMU se
ve en el escritorio de Windows):
```bash
sudo apt install -y x11-apps
xeyes      # debe abrir una ventanita con ojos; ciérrala
```

**6. Crear el contenedor de macOS** (en la terminal de **Ubuntu**):
```bash
docker run -it --name macos-p3 \
    --device /dev/kvm \
    -p 50922:10022 \
    -e "DISPLAY=${DISPLAY:-:0.0}" \
    -v /mnt/wslg/.X11-unix:/tmp/.X11-unix \
    -e GENERATE_UNIQUE=true \
    -e MASTER_PLIST_URL='https://raw.githubusercontent.com/sickcodes/osx-serial-generator/master/config-custom.plist' \
    -e SHORTNAME=ventura \
    -e RAM=9 \
    -e SMP=8 \
    -e CORES=4 \
    sickcodes/docker-osx:latest
```
- La primera vez descarga la imagen, que pesa varios GB.
- Si la ventana no aparece, repite el comando cambiando
  `DISPLAY=${DISPLAY:-:0.0}` por `DISPLAY=${DISPLAY:-:0}` (la segunda variante
  del README). Antes borra el contenedor fallido con `docker rm macos-p3`,
  **solo mientras macOS aún no esté instalado**.
- **Recursos:** `RAM=9` GB para macOS deja unos 4 GB a WSL y Docker dentro de
  los 13 GB. `SMP=8` y `CORES=4` son los valores del README.

**Para volver a entrar otro día:** abre Docker Desktop y, en Ubuntu, corre
`docker start -ai macos-p3`. **No** vuelvas a usar `docker run`, porque crearía
un disco nuevo vacío.

### 2B. Linux

```bash
git clone https://github.com/gabrielhuav/MacOS-Docker.git
sudo apt install qemu qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virt-manager libguestfs-tools
sudo systemctl enable --now libvirtd virtlogd
echo 1 | sudo tee /sys/module/kvm/parameters/ignore_msrs
sudo modprobe kvm
xhost +local:docker          # para que se vea la ventana de QEMU

docker run -it --name macos-p3 \
  --device /dev/kvm \
  -p 50922:10022 \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -e "DISPLAY=${DISPLAY:-:0.0}" \
  -e GENERATE_UNIQUE=true \
  -e MASTER_PLIST_URL='https://raw.githubusercontent.com/sickcodes/osx-serial-generator/master/config-custom.plist' \
  -e SHORTNAME=ventura \
  -e RAM=10 -e SMP=6 -e CORES=6 \
  sickcodes/docker-osx:latest
```

**Recursos de la VM:** deja al anfitrión al menos 4 GB de RAM y 2 hilos. Por
ejemplo, con 16 GB y 8 hilos usa `RAM=10`, `SMP=6`, `CORES=6`; con 32 GB usa
`RAM=16`. La opción `--name macos-p3` sirve para volver a arrancar el mismo
disco después con `docker start -ai macos-p3`.

### 2C. Instalar macOS dentro de la ventana de QEMU (igual en Windows y Linux)
1. **macOS Base System** → **Utilidad de Discos** → borrar el disco **QEMU
   (~270 GB)** con el nombre `MacOS`, formato **APFS** y esquema **GUID**.
2. **Reinstalar macOS Ventura** en el disco `MacOS`. Tarda alrededor de 1 h.
3. Cuando reinicie, elige **macOS Installer** y después el disco `MacOS`.
4. En el asistente, **omite el Apple ID** (se agrega después para Xcode).

✅ **Resultado esperado:** el escritorio de macOS Ventura. En Safari abre
<https://www.apple.com/mx/> y confirma que carga.

📸 Capturas:
- `02-docker-arrancando.png`: terminal con `docker run` y la ventana de QEMU
- `03-macos-escritorio.png`: escritorio de macOS, con «Acerca de esta Mac»
- `04-internet-safari.png`: Safari con una página cargada

> ⚠️ **No borres el contenedor** (`docker rm`), porque ahí vive el disco de
> macOS. Para apagar, usa  › Apagar. Para volver a entrar,
> `docker start -ai macos-p3`.

---

## 3. Instalar Xcode 15.2

1. Crea o usa un **Apple ID gratuito**.
2. En Safari (dentro de macOS) entra a <https://developer.apple.com/download/all/>,
   busca **Xcode 15.2** y descarga `Xcode_15.2.xip` (~3 GB). La App Store
   ofrecerá la versión más nueva, que **no** se puede instalar en Ventura.
3. Doble clic en el `.xip` para descomprimirlo (tarda 20–40 min en la VM) y
   arrastra **Xcode.app** a **Aplicaciones**.
4. En Terminal:
   ```bash
   sudo xcode-select -s /Applications/Xcode.app
   sudo xcodebuild -license accept
   xcodebuild -runFirstLaunch
   xcodebuild -version        # → Xcode 15.2
   ```
5. Abre Xcode → **Settings › Platforms** e instala **iOS 17.2 Simulator**
   (~7 GB), si no viene incluido.

✅ **Resultado esperado:** `xcodebuild -version` muestra `Xcode 15.2` y
`xcrun simctl list devices available | grep -E "iPhone 15|iPad"` lista al
menos un iPhone 15 y un iPad.

📸 Capturas:
- `05-xcode-instalado.png`: Xcode › About Xcode
- `06-simuladores.png`: Window › Devices and Simulators › Simulators (iPhone y iPad)

---

## 4. Herramientas adicionales

```bash
# Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile && eval "$(/usr/local/bin/brew shellenv)"

brew install xcodegen cocoapods git gh
brew install --cask temurin@17        # JDK 17 para el Ej. 5

# Flutter 3.24.0 (versión exacta)
cd ~ && git clone https://github.com/flutter/flutter.git -b 3.24.0 --depth 1
echo 'export PATH="$HOME/flutter/bin:$PATH"' >> ~/.zprofile && source ~/.zprofile
flutter --version            # → Flutter 3.24.0
flutter precache --ios
flutter doctor
```

**Swift Package Manager** ya viene con Xcode: `swift package --version`.

Si Homebrew compila desde el código fuente y tarda mucho (Ventura ya no es
la versión principal de Homebrew), estas son las alternativas:
- XcodeGen: `curl -LO https://github.com/yonaskolb/XcodeGen/releases/latest/download/xcodegen.zip && unzip xcodegen.zip && sudo cp xcodegen/bin/xcodegen /usr/local/bin/`
- CocoaPods: `sudo gem install cocoapods`

✅ **Resultado esperado:** en `flutter doctor`, las líneas **Flutter** y
**Xcode** con ✓. La línea Android puede salir con ✗, no importa porque el APK
se compila en Linux.

📸 `07-brew-cocoapods-versiones.png`: terminal con `brew --version`,
`xcodegen --version`, `pod --version`, `swift package --version`,
`flutter --version` y `java -version`.

---

## 5. Traer el repositorio (dentro de macOS)

Las capturas se toman dentro de macOS, así que clonas y subes desde ahí. En la
Terminal de macOS:
```bash
brew install gh
gh auth login          # GitHub.com → HTTPS → Login with a web browser (cuenta Alexis177)
cd ~
git clone https://github.com/jesusGoliat/Practica-3-Aplicaciones-nativas.git Practica3
cd Practica3
git config --global user.name  "David Alexis Hernandez Gonzalez"
git config --global user.email "hernandezgonzalezdavidalexis@gmail.com"
```
✅ `git log --oneline | head -3` muestra commits recientes (entre ellos
`fix(ej5): import de UIKit faltante…`).

> Clónalo en una ruta **sin espacios ni acentos** (`~/Practica3`). No lo
> pases por USB ni por WhatsApp.

Estructura esperada:
```text
Practica3/
├── ej1-entorno/HolaMundo/project.yml
├── ej2-gestor-ios/project.yml
├── ej3-camara-ios/project.yml, muestras/
├── ej4-flutter-camara/pubspec.yaml, ios/
├── ej5-kmp-gestor/composeApp/, iosApp/project.yml
└── binarios/
```

---

## 6. Ejercicio 1: proyecto de prueba

```bash
cd ~/Practica3/ej1-entorno/HolaMundo
xcodegen generate            # → "Created project at .../HolaMundo.xcodeproj"
open HolaMundo.xcodeproj
```
En Xcode: arriba elige el esquema **HolaMundo** y el destino **iPhone 15**, y
pulsa **⌘R**.

✅ **Resultado esperado:** el simulador abre «¡Hola, ESCOM!» con el ícono de
Swift en guinda, el nombre del dispositivo y un botón «Toques: N».

📸 `ej1-entorno/img/08-holamundo-simulador.png`

**Cómo tomar las capturas del simulador (para todos los ejercicios).** Usa la
terminal para que el archivo quede con el nombre correcto:
```bash
xcrun simctl io booted screenshot ~/Practica3/ej2-gestor-ios/img/01-raiz-documents-guinda-claro.png
xcrun simctl ui booted appearance dark    # cambia a modo oscuro (light para volver)
```

---

## 7. Ejercicio 2: Gestor de Archivos

```bash
cd ~/Practica3/ej2-gestor-ios
xcodegen generate
open GestorArchivos.xcodeproj       # esquema GestorArchivos, iPhone 15, ⌘R
```
Por terminal (opcional):
```bash
xcodebuild -scheme GestorArchivos -destination 'platform=iOS Simulator,name=iPhone 15' -derivedDataPath build build
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/GestorArchivos.app
xcrun simctl launch booted mx.ipn.escom.p3.gestorarchivos
```

✅ **Resultado esperado:** pestaña **Archivos › Ubicaciones** con
*Documents, Inbox, tmp*. Dentro de Documents están `Bienvenida.txt`,
`Notas.md`, `config.json`, `Reporte.pdf`, `datos.xyz` y las carpetas
`Imágenes` y `Proyectos`.

📸 Capturas en `ej2-gestor-ios/img/` (en este orden):

| Archivo | Qué debe verse | Cómo llegar |
|---|---|---|
| `01-raiz-documents-guinda-claro.png` | Lista de Documents, tema Guinda, modo claro | Archivos › Documents |
| `02-azul-oscuro.png` | La misma lista en Azul ESCOM, modo oscuro | Ajustes › Azul ESCOM + `appearance dark` |
| `03-subcarpeta-ruta.png` | Encabezado `Documents › Proyectos › 2026` | Entrar a Proyectos › 2026 |
| `04-busqueda-orden.png` | Búsqueda «no» y menú Opciones abierto | Deslizar hacia abajo para ver la búsqueda; ⋯ |
| `05-menu-contextual.png` | Menú al mantener presionado | Mantener presionado `Notas.md` |
| `06-swipe-eliminar-confirmacion.png` | Diálogo «¿Eliminar…?» | Deslizar `datos.xyz` a la izquierda › Eliminar |
| `07-crear-carpeta.png` | Alerta «Nueva carpeta» | ⋯ › Nueva carpeta |
| `08-renombrar.png` | Alerta «Renombrar» | Menú contextual › Renombrar |
| `09-mover-copiar.png` | Hoja «Copiar a…» | Menú contextual › Copiar a… |
| `10-visor-texto.png` | Contenido de `Notas.md` | Tocar `Notas.md` |
| `11-imagen-zoom-rotacion.png` | `escom.png` con zoom y giro | Imágenes › escom.png; ⌥ + arrastrar = pellizcar/girar |
| `12-quicklook.png` | `Reporte.pdf` en Quick Look | Tocar `Reporte.pdf` |
| `13-importar-document-picker.png` | Selector de Archivos | ⋯ › Importar desde Archivos |
| `14-compartir.png` | Hoja de compartir | Menú contextual › Compartir |
| `15-favoritos.png` | Pestaña Favoritos con elementos | Deslizar a la derecha › Favorito en 2–3 archivos |
| `16-recientes.png` | Pestaña Recientes | Abrir 2–3 archivos antes |
| `17-ajustes-tema.png` | Ajustes con los dos temas | Pestaña Ajustes |
| `18-horizontal.png` | Lista en horizontal | ⌘→ en el simulador |
| `19-app-archivos-muestra-documentos.png` | App **Archivos** › En mi iPhone › Gestor P3 | Abrir la app Archivos del simulador |
| `20-error-archivo-no-soportado.png` | Aviso de `dañada.jpg` o `datos.xyz` | Tocar `Imágenes/dañada.jpg` |
| `21-restaura-ultima-carpeta.png` (opcional) | Al reabrir, vuelve a la última carpeta | Cerrar y reabrir la app |

> **Gestos en el simulador:** mantener **⌥ Option** y arrastrar simula
> pellizcar o girar con dos dedos. Deslizar = arrastrar con el mouse.

**Opcional, Mac Catalyst (valor agregado):** en Xcode elige el destino
**My Mac (Mac Catalyst)** y pulsa ⌘R. Toma `22-mac-catalyst.png`. Si falla,
no pasa nada: es opcional.

---

## 8. Ejercicio 3: Cámara y Micrófono

```bash
cd ~/Practica3/ej3-camara-ios
xcodegen generate
open CamaraMic.xcodeproj            # esquema CamaraMic, iPhone 15, ⌘R
# Con el simulador ya encendido, llena su fototeca:
xcrun simctl addmedia booted muestras/muestra-guinda.png muestras/muestra-azul.png muestras/muestra-degradado.png
# Deja el audio de muestra en la carpeta de la app (visible en Archivos):
cp muestras/tono-440hz.wav "$(xcrun simctl get_app_container booted mx.ipn.escom.p3.camaramic data)/Documents/"
```

✅ **Resultado esperado:** en la pestaña Cámara aparece **«Este dispositivo no
tiene cámara»** con el botón **«Elegir de la fototeca»**. Es lo correcto en el
simulador; la práctica acepta esta fuente alternativa.

📸 Capturas en `ej3-camara-ios/img/`:

| Archivo | Qué debe verse | Cómo llegar |
|---|---|---|
| `01-permiso-camara.png` | Alerta de permiso (o la de ubicación al abrir) | Primer arranque |
| `02-permiso-microfono.png` | Alerta «"Cámara P3" quiere acceder al micrófono» | Grabadora › botón rojo (primera vez) |
| `03-sin-camara-aviso-phpicker.png` | Aviso «no tiene cámara» + botón | Pestaña Cámara |
| `03b-phpicker-fototeca.png` | Selector con las 3 fotos de muestra | Elegir de la fototeca |
| `03c-revision-filtros.png` | Pantalla «Revisar foto» con la fila de filtros | Elegir una foto |
| `04-filtros.png` | La misma foto con filtro Sepia o Noir | Tocar un filtro |
| `05-grabando-audio-nivel.png` | Grabando: contador, círculo y onda | Grabadora › grabar |
| `06-ajustes-audio.png` | Sensibilidad y temporizador (p. ej. Alta + 15 s) | Grabadora |
| `07-galeria.png` | Cuadrícula con varias fotos | Galería › Fotos (guarda 3–4 antes) |
| `08-editor-imagen.png` | Editor con girar, recortar y filtros | Galería › foto › Editar |
| `09-reproductor.png` | Reproductor con barra de avance | Galería › Audios › un audio |
| `10-albumes.png` | Chips de álbumes y un álbum filtrado | Galería › + › «Escuela» |
| `11-etiquetas-metadatos.png` | Hoja de metadatos o bloque de info con fecha, ubicación y etiquetas | Foto › Etiquetas |
| `12-exportar.png` | Hoja de compartir | Foto › Exportar |
| `13-importar.png` | Menú Importar o selector de Archivos con `tono-440hz.wav` | Galería › Importar › Archivos › En mi iPhone › Cámara P3 |
| `14-tema-azul-oscuro.png` | Galería en Azul ESCOM, modo oscuro | Ajustes |
| `15-guinda-claro.png` | Galería en Guinda, modo claro | Ajustes |

**Ubicación:** el simulador usa una ubicación simulada (Features › Location ›
Apple). Acepta el permiso para que se guarde latitud y longitud.

**Micrófono:** si en la VM el medidor no se mueve, la grabación igual se
guarda (en silencio). Es una limitación de la virtualización; ya está en
«Problemas conocidos». Para `09-reproductor.png` usa `tono-440hz.wav`
importado.

---

## 9. Ejercicio 4: Flutter en iOS

```bash
cd ~/Practica3/ej4-flutter-camara
flutter pub get
cd ios && pod install && cd ..      # → "Pod installation complete!"
open -a Simulator
flutter devices                      # debe listar "iPhone 15 (mobile) • … • ios • … (simulator)"
flutter run -d "iPhone 15"
```
La primera compilación tarda de 10 a 20 min en la VM.

✅ **Resultado esperado:** la app «Cámara P3» con 4 pestañas (Cámara, Audio,
Galería, Ajustes). En Cámara aparece «Este dispositivo no tiene cámara» con
el botón **Elegir de la fototeca**.

📸 Capturas en `ej4-flutter-camara/img/` con prefijo `ios-`:
- `ios-01-sin-camara.png`
- `ios-02-fototeca-filtro.png`
- `ios-03-grabadora.png`
- `ios-04-galeria.png`
- `ios-05-visor-editor.png`
- `ios-06-reproductor.png`
- `ios-07-ajustes-azul-oscuro.png`
- `ios-08-guinda-claro.png`

Las capturas `android-NN-…` las toma Jesús en Linux con el celular.

**Binario iOS:**
```bash
flutter build ios --simulator --debug
cd build/ios/iphonesimulator && zip -r ~/Practica3/binarios/ej4-flutter-camara-ios-simulador.zip Runner.app
```

---

## 10. Ejercicio 5: Kotlin Multiplatform en iOS

```bash
cd ~/Practica3/ej5-kmp-gestor
java -version                                   # → 17
# Gradle necesita la ruta de un Android SDK aunque solo compiles iOS:
brew install --cask android-commandlinetools
yes | sdkmanager --licenses >/dev/null
sdkmanager "platforms;android-35" "build-tools;35.0.0"
echo "sdk.dir=$(brew --prefix)/share/android-commandlinetools" > local.properties

./gradlew :composeApp:linkDebugFrameworkIosX64  # → BUILD SUCCESSFUL (primera vez: 10–20 min, descarga ~1 GB)
cd iosApp && xcodegen generate && open iosApp.xcodeproj   # esquema iosApp, iPhone 15, ⌘R
```

✅ **Resultado esperado:** la app «Gestor KMP» con barra inferior (Archivos,
Favoritos, Recientes, Ajustes). En Documentos aparecen `Imágenes`, `Notas`,
`Práctica 3` y `binario.dat`.

📸 Capturas en `ej5-kmp-gestor/img/` con prefijo `ios-`:
- `ios-01-documentos.png`
- `ios-02-subcarpeta-migas.png`
- `ios-03-menu-contextual.png`
- `ios-04-visor-imagen.png`
- `ios-05-visor-texto.png`
- `ios-06-favoritos.png`
- `ios-07-azul-oscuro.png`
- `ios-08-importar.png`
- `estructura-proyecto.png`: Xcode o Finder mostrando `commonMain`, `androidMain` e `iosMain`

**Binario iOS:** Xcode › Product › Show Build Folder in Finder ›
`Products/Debug-iphonesimulator/iosApp.app`, comprimido como
`binarios/ej5-kmp-gestor-ios-simulador.zip`. Lo mismo con Ej. 2 y 3
(`GestorArchivos.app`, `CamaraMic.app`).

---

## 11. Subir tus commits

Revisa `REPARTO_COMMITS.md` (sección Integrante 2). Antes de cada `git push`:
```bash
git status && git diff --cached --stat
git log -1 --format='%an <%ae>%n%B'   # autor = tú; sin líneas Co-Authored-By
```

---

## 12. Errores comunes en macOS virtualizado

| Síntoma | Causa | Solución |
|---|---|---|
| (Windows) `docker: Cannot connect to the Docker daemon` en Ubuntu | Docker Desktop cerrado o sin integración WSL | Abre Docker Desktop; Settings › Resources › WSL Integration › Ubuntu activado |
| (Windows) `kvm-ok`: «/dev/kvm does not exist» | Falta la virtualización anidada o VT-x | Revisa `nestedVirtualization=true` en `.wslconfig`, luego `wsl --shutdown`; activa VT-x en la BIOS; `wsl --update` |
| (Windows) No aparece la ventana de QEMU | DISPLAY o WSLg | Prueba `xeyes`; usa la variante `DISPLAY=${DISPLAY:-:0}`; `wsl --update` |
| (Windows) macOS muy lento o el contenedor se cierra solo | WSL con poca memoria | `.wslconfig` con `memory=13GB` y `swap=8GB`; cierra Chrome y juegos mientras trabajas |
| El simulador tarda minutos o se queda en negro | Sin aceleración de GPU en QEMU | Usa **un solo** simulador (iPhone SE o iPhone 15, no Pro Max); cierra el canvas de Previews (⌥⌘↩); `defaults write com.apple.iphonesimulator GraphicsQualityOverride 10`; sube `RAM`/`CORES` del contenedor |
| La App Store dice que Xcode requiere macOS 14 | Ventura solo admite hasta Xcode 15.2 | Descarga el `.xip` de 15.2 en developer.apple.com/download/all |
| «iOS 17.2 Platform Not Installed» | Falta el runtime | Xcode › Settings › Platforms › iOS 17.2, o `xcodebuild -downloadPlatform iOS` |
| «No space left on device» | El disco o el `.xip` llenan la VM | `xcrun simctl delete unavailable`; `rm -rf ~/Library/Developer/Xcode/DerivedData`; borra el `.xip` al descomprimir |
| «Signing for "X" requires a development team» | Se eligió un iPhone real | En el **simulador** no hace falta firma: elige «iPhone 15». Si alguien presta un iPhone: Signing & Capabilities › Team › Personal Team y cambia el bundle id (sufijo con iniciales) |
| `xcodegen: command not found` | No está en el PATH | `eval "$(/usr/local/bin/brew shellenv)"` o usa el binario del zip (paso 4) |
| `pod install` falla con Unicode o encoding | Locale | `export LANG=en_US.UTF-8` y reintenta |
| «CocoaPods not installed» en `flutter run` | Falta `pod` | `brew install cocoapods` o `sudo gem install cocoapods` |
| Flutter: «Xcode installation is incomplete» | Falta aceptar la licencia o el first launch | `sudo xcodebuild -license accept && xcodebuild -runFirstLaunch` |
| Ej5: «SDK location not found» | Gradle necesita un Android SDK | Paso 10: `local.properties` con `sdk.dir` |
| Ej5: «Unable to locate a Java Runtime» dentro de Xcode | Xcode no hereda el PATH | `brew install --cask temurin@17` (el script usa `/usr/libexec/java_home -v 17`) |
| Ej5: «Undefined symbols … ComposeApp» o «framework not found» | El framework no se generó para x86_64 | `./gradlew :composeApp:linkDebugFrameworkIosX64` y después ⌘⇧K (Clean) + ⌘R |
| Ej5: advertencia «Xcode version not supported» | Kotlin 2.0.21 se probó con Xcode más nuevo | Es solo una advertencia; si bloquea, agrega `kotlin.apple.xcodeCompatibility.nowarn=true` a `gradle.properties` |
| Rutas con espacios rompen los scripts | `~/Mis Documentos/…` | Clona en `~/Practica3` |
| Hora de la VM incorrecta → errores TLS en brew o pub | Reloj desincronizado | Ajustes › General › Fecha y hora › automática |
| La VM no arranca después de apagarla | Se creó un contenedor nuevo con `docker run` | Usa `docker start -ai macos-p3` (el disco vive en ese contenedor) |
| El micrófono graba silencio | La VM no tiene entrada de audio | Limitación conocida; usa `tono-440hz.wav` para el reproductor |
| La fototeca está vacía en PHPicker | Falta `simctl addmedia` o se usó «Erase All Content» | Repite `xcrun simctl addmedia booted muestras/*.png` |

**Plan B:** si la VM no arranca, avisa **ese mismo día** al profesor y
coordínate con otro equipo (lo pide la práctica). Los binarios de simulador
del CI de GitHub (vienen en `respaldo/apps-compiladas-en-github/` del
zip de Alexis) sirven como respaldo para instalar con `xcrun simctl install`.
Son universales (x86_64 + arm64), así que corren en el simulador de la VM.
