import 'dart:io';
import 'dart:isolate';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

/// Maneja los archivos físicos: fotos, audios y miniaturas dentro del
/// directorio de documentos de la app (sandbox en iOS, almacenamiento
/// interno en Android). No requiere Internet.
class AlmacenArchivos {
  AlmacenArchivos(this.raiz);

  /// Directorio base, normalmente `getApplicationDocumentsDirectory()`.
  final Directory raiz;

  static const tamanoMiniatura = 320;

  Directory get _fotos => Directory(p.join(raiz.path, 'fotos'));
  Directory get _audios => Directory(p.join(raiz.path, 'audios'));
  Directory get _miniaturas => Directory(p.join(raiz.path, 'miniaturas'));

  Future<void> preparar() async {
    for (final d in [_fotos, _audios, _miniaturas]) {
      await d.create(recursive: true);
    }
  }

  String _nombreNuevo(String extension) =>
      '${DateTime.now().millisecondsSinceEpoch}${extension.startsWith('.') ? extension : '.$extension'}';

  /// Procesa una foto en un isolate (para no congelar la interfaz): corrige la
  /// orientación EXIF, aplica filtro y giro, la guarda como JPEG y genera la
  /// miniatura. Devuelve (rutaFoto, rutaMiniatura).
  Future<(String, String)> procesarFoto(
    String origen, {
    List<double>? matriz,
    int giroGrados = 0,
    String? destinoExistente,
  }) async {
    await preparar();
    final destino = destinoExistente ?? p.join(_fotos.path, _nombreNuevo('.jpg'));
    final miniatura = p.join(_miniaturas.path, '${p.basenameWithoutExtension(destino)}.jpg');

    await Isolate.run(() => _procesar(origen, destino, miniatura, matriz, giroGrados));
    return (destino, miniatura);
  }

  static void _procesar(String origen, String destino, String miniatura, List<double>? matriz, int giro) {
    final bytes = File(origen).readAsBytesSync();
    var imagen = img.decodeImage(bytes);
    if (imagen == null) {
      throw const FormatException('El archivo no es una imagen válida o está dañado.');
    }
    imagen = img.bakeOrientation(imagen);
    if (giro % 360 != 0) imagen = img.copyRotate(imagen, angle: giro);
    if (matriz != null) aplicarMatriz(imagen, matriz);

    File(destino).writeAsBytesSync(img.encodeJpg(imagen, quality: 90));
    final chica = img.copyResize(
      imagen,
      width: imagen.width >= imagen.height ? tamanoMiniatura : null,
      height: imagen.height > imagen.width ? tamanoMiniatura : null,
    );
    File(miniatura).writeAsBytesSync(img.encodeJpg(chica, quality: 75));
  }

  /// Aplica una matriz de color 4x5 (misma convención que ColorFilter.matrix).
  static void aplicarMatriz(img.Image imagen, List<double> m) {
    for (final px in imagen) {
      final r = px.r.toDouble(), g = px.g.toDouble(), b = px.b.toDouble(), a = px.a.toDouble();
      px
        ..r = (m[0] * r + m[1] * g + m[2] * b + m[3] * a + m[4]).clamp(0, 255)
        ..g = (m[5] * r + m[6] * g + m[7] * b + m[8] * a + m[9]).clamp(0, 255)
        ..b = (m[10] * r + m[11] * g + m[12] * b + m[13] * a + m[14]).clamp(0, 255);
    }
  }

  /// Copia un audio a la carpeta de la app y devuelve la nueva ruta.
  Future<String> guardarAudio(String origen) async {
    await preparar();
    final destino = p.join(_audios.path, _nombreNuevo(p.extension(origen).isEmpty ? '.m4a' : p.extension(origen)));
    await File(origen).copy(destino);
    return destino;
  }

  /// Indica si la ruta ya está en la carpeta de audios de la app (grabaciones).
  bool esAudioPropio(String ruta) => p.isWithin(_audios.path, ruta);

  /// Ruta donde el grabador debe escribir la siguiente grabación.
  Future<String> rutaGrabacionNueva() async {
    await preparar();
    return p.join(_audios.path, _nombreNuevo('.m4a'));
  }

  Future<void> borrar(String? ruta) async {
    if (ruta == null) return;
    final f = File(ruta);
    if (await f.exists()) await f.delete();
  }

  static const extensionesImagen = {'.jpg', '.jpeg', '.png', '.heic', '.webp', '.gif', '.bmp'};
  static const extensionesAudio = {'.m4a', '.aac', '.mp3', '.wav', '.caf', '.ogg'};
}
