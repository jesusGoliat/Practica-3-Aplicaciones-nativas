import '../entities/elemento_multimedia.dart';
import '../entities/filtro_foto.dart';
import '../repositories/repositorio_multimedia.dart';

// Casos de uso de la capa de dominio. Cada uno expone una sola acción del
// usuario y delega en el repositorio; así la presentación no sabe si los
// datos viven en SQLite, en archivos o en otro lugar.

class ObtenerGaleria {
  const ObtenerGaleria(this._repo);
  final RepositorioMultimedia _repo;

  Future<List<ElementoMultimedia>> call({TipoMultimedia? tipo, String? album}) =>
      _repo.obtenerTodos(tipo: tipo, album: album);
}

class GuardarFoto {
  const GuardarFoto(this._repo);
  final RepositorioMultimedia _repo;

  Future<ElementoMultimedia> call(String ruta, {FiltroFoto filtro = FiltroFoto.ninguno, String? album}) =>
      _repo.guardarFoto(ruta, filtro: filtro, album: album ?? ElementoMultimedia.albumGeneral);
}

class GuardarAudio {
  const GuardarAudio(this._repo);
  final RepositorioMultimedia _repo;

  Future<ElementoMultimedia> call(String ruta, {required int duracionMs, String? album}) =>
      _repo.guardarAudio(ruta, duracionMs: duracionMs, album: album ?? ElementoMultimedia.albumGeneral);
}

class ImportarArchivo {
  const ImportarArchivo(this._repo);
  final RepositorioMultimedia _repo;

  Future<ElementoMultimedia> call(String ruta) => _repo.importar(ruta);
}

class EditarFoto {
  const EditarFoto(this._repo);
  final RepositorioMultimedia _repo;

  Future<ElementoMultimedia> call(ElementoMultimedia foto, {FiltroFoto? filtro, int giroGrados = 0}) =>
      _repo.editarFoto(foto, filtro: filtro, giroGrados: giroGrados);
}

class ActualizarMetadatos {
  const ActualizarMetadatos(this._repo);
  final RepositorioMultimedia _repo;

  Future<void> call(ElementoMultimedia elemento) => _repo.actualizar(elemento);
}

class EliminarElemento {
  const EliminarElemento(this._repo);
  final RepositorioMultimedia _repo;

  Future<void> call(ElementoMultimedia elemento) => _repo.eliminar(elemento);
}

class GestionarAlbumes {
  const GestionarAlbumes(this._repo);
  final RepositorioMultimedia _repo;

  Future<List<String>> obtener() => _repo.obtenerAlbumes();
  Future<void> crear(String nombre) => _repo.crearAlbum(nombre.trim());
}
