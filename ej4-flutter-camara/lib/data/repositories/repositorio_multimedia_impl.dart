import 'package:path/path.dart' as p;

import '../../domain/entities/elemento_multimedia.dart';
import '../../domain/entities/filtro_foto.dart';
import '../../domain/repositories/repositorio_multimedia.dart';
import '../datasources/almacen_archivos.dart';
import '../datasources/base_datos_local.dart';
import '../models/elemento_modelo.dart';

/// Implementación del repositorio: combina SQLite (metadatos) con el
/// sistema de archivos (contenido).
class RepositorioMultimediaImpl implements RepositorioMultimedia {
  RepositorioMultimediaImpl(this._db, this._archivos);

  final BaseDatosLocal _db;
  final AlmacenArchivos _archivos;

  @override
  Future<List<ElementoMultimedia>> obtenerTodos({TipoMultimedia? tipo, String? album}) async {
    final filas = await _db.consultar(tipo: tipo?.name, album: album);
    return filas.map(ElementoModelo.deFila).toList();
  }

  @override
  Future<ElementoMultimedia> guardarFoto(
    String rutaOrigen, {
    FiltroFoto filtro = FiltroFoto.ninguno,
    String album = ElementoMultimedia.albumGeneral,
  }) async {
    final (ruta, miniatura) = await _archivos.procesarFoto(rutaOrigen, matriz: filtro.matriz);
    return _insertar(ElementoMultimedia(
      tipo: TipoMultimedia.foto,
      ruta: ruta,
      rutaMiniatura: miniatura,
      fecha: DateTime.now(),
      album: album,
      filtro: filtro.name,
    ));
  }

  @override
  Future<ElementoMultimedia> guardarAudio(
    String rutaOrigen, {
    required int duracionMs,
    String album = ElementoMultimedia.albumGeneral,
  }) async {
    // Las grabaciones ya se escriben dentro de la carpeta de la app; solo se
    // copian los audios que vienen de fuera (importados).
    final yaEsLocal = _archivos.esAudioPropio(rutaOrigen);
    final ruta = yaEsLocal ? rutaOrigen : await _archivos.guardarAudio(rutaOrigen);
    return _insertar(ElementoMultimedia(
      tipo: TipoMultimedia.audio,
      ruta: ruta,
      fecha: DateTime.now(),
      album: album,
      duracionMs: duracionMs,
    ));
  }

  @override
  Future<ElementoMultimedia> importar(String rutaOrigen) {
    final ext = p.extension(rutaOrigen).toLowerCase();
    if (AlmacenArchivos.extensionesImagen.contains(ext)) {
      return guardarFoto(rutaOrigen);
    }
    if (AlmacenArchivos.extensionesAudio.contains(ext)) {
      return guardarAudio(rutaOrigen, duracionMs: 0);
    }
    throw FormatException('Tipo de archivo no soportado: $ext');
  }

  @override
  Future<ElementoMultimedia> editarFoto(ElementoMultimedia foto, {FiltroFoto? filtro, int giroGrados = 0}) async {
    // Se reprocesa sobre el mismo archivo para no duplicar espacio.
    await _archivos.procesarFoto(
      foto.ruta,
      matriz: filtro?.matriz,
      giroGrados: giroGrados,
      destinoExistente: foto.ruta,
    );
    final editada = foto.copyWith(filtro: filtro?.name ?? foto.filtro);
    await actualizar(editada);
    return editada;
  }

  @override
  Future<void> actualizar(ElementoMultimedia elemento) =>
      _db.actualizar(elemento.id!, ElementoModelo.aFila(elemento));

  @override
  Future<void> eliminar(ElementoMultimedia elemento) async {
    await _archivos.borrar(elemento.ruta);
    await _archivos.borrar(elemento.rutaMiniatura);
    await _db.eliminar(elemento.id!);
  }

  @override
  Future<List<String>> obtenerAlbumes() => _db.albumes();

  @override
  Future<void> crearAlbum(String nombre) => _db.crearAlbum(nombre);

  Future<ElementoMultimedia> _insertar(ElementoMultimedia e) async {
    final id = await _db.insertar(ElementoModelo.aFila(e));
    return e.copyWith(id: id);
  }
}
