import 'package:flutter/foundation.dart';

import '../../domain/entities/elemento_multimedia.dart';
import '../../domain/entities/filtro_foto.dart';
import '../../domain/usecases/casos_uso_multimedia.dart';

/// Estado de la galería. Expone la lista filtrada por tipo y álbum y las
/// operaciones que la interfaz puede pedir. Solo usa casos de uso.
class EstadoGaleria extends ChangeNotifier {
  EstadoGaleria({
    required this.obtenerGaleria,
    required this.guardarFoto,
    required this.guardarAudio,
    required this.importarArchivo,
    required this.editarFoto,
    required this.actualizarMetadatos,
    required this.eliminarElemento,
    required this.albumes,
  });

  final ObtenerGaleria obtenerGaleria;
  final GuardarFoto guardarFoto;
  final GuardarAudio guardarAudio;
  final ImportarArchivo importarArchivo;
  final EditarFoto editarFoto;
  final ActualizarMetadatos actualizarMetadatos;
  final EliminarElemento eliminarElemento;
  final GestionarAlbumes albumes;

  List<ElementoMultimedia> elementos = [];
  List<String> listaAlbumes = [];
  TipoMultimedia tipo = TipoMultimedia.foto;
  String? albumSeleccionado;
  bool cargando = false;
  String? error;

  Future<void> cargar() async {
    cargando = true;
    notifyListeners();
    try {
      listaAlbumes = await albumes.obtener();
      elementos = await obtenerGaleria(tipo: tipo, album: albumSeleccionado);
      error = null;
    } catch (e) {
      error = 'No se pudo leer la galería: $e';
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  void cambiarTipo(TipoMultimedia t) {
    tipo = t;
    cargar();
  }

  void filtrarAlbum(String? album) {
    albumSeleccionado = album;
    cargar();
  }

  Future<ElementoMultimedia> agregarFoto(String ruta, FiltroFoto filtro) async {
    final e = await guardarFoto(ruta, filtro: filtro);
    await cargar();
    return e;
  }

  Future<ElementoMultimedia> agregarAudio(String ruta, int duracionMs) async {
    final e = await guardarAudio(ruta, duracionMs: duracionMs);
    await cargar();
    return e;
  }

  Future<ElementoMultimedia> importar(String ruta) async {
    final e = await importarArchivo(ruta);
    await cargar();
    return e;
  }

  Future<ElementoMultimedia> editar(ElementoMultimedia foto, {FiltroFoto? filtro, int giro = 0}) async {
    final e = await editarFoto(foto, filtro: filtro, giroGrados: giro);
    await cargar();
    return e;
  }

  Future<void> guardarMetadatos(ElementoMultimedia e) async {
    await actualizarMetadatos(e);
    await cargar();
  }

  Future<void> eliminar(ElementoMultimedia e) async {
    await eliminarElemento(e);
    await cargar();
  }

  Future<void> crearAlbum(String nombre) async {
    if (nombre.trim().isEmpty) return;
    await albumes.crear(nombre);
    await cargar();
  }
}
