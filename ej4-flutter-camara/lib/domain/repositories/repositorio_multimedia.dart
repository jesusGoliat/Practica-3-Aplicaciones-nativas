import '../entities/elemento_multimedia.dart';
import '../entities/filtro_foto.dart';

/// Contrato del almacenamiento de fotos y audios. La capa de datos lo
/// implementa con sqflite y el sistema de archivos; la presentación solo
/// conoce esta interfaz.
abstract class RepositorioMultimedia {
  Future<List<ElementoMultimedia>> obtenerTodos({TipoMultimedia? tipo, String? album});

  /// Copia la foto al almacenamiento de la app, aplica el filtro y genera su
  /// miniatura.
  Future<ElementoMultimedia> guardarFoto(String rutaOrigen, {FiltroFoto filtro, String album});

  Future<ElementoMultimedia> guardarAudio(String rutaOrigen, {required int duracionMs, String album});

  /// Importa un archivo externo (galería o app Archivos) según su extensión.
  Future<ElementoMultimedia> importar(String rutaOrigen);

  Future<ElementoMultimedia> editarFoto(ElementoMultimedia foto, {FiltroFoto? filtro, int giroGrados});

  Future<void> actualizar(ElementoMultimedia elemento);

  Future<void> eliminar(ElementoMultimedia elemento);

  Future<List<String>> obtenerAlbumes();

  Future<void> crearAlbum(String nombre);
}
