import '../data/datasources/almacen_archivos.dart';
import '../data/datasources/base_datos_local.dart';
import '../data/datasources/preferencias.dart';
import '../data/repositories/repositorio_multimedia_impl.dart';
import '../domain/usecases/casos_uso_multimedia.dart';
import '../presentation/providers/estado_ajustes.dart';
import '../presentation/providers/estado_galeria.dart';

/// Composición de dependencias (inyección manual). Es el único lugar que
/// conoce las tres capas; el resto solo depende de abstracciones.
class Dependencias {
  Dependencias({required BaseDatosLocal db, required this.archivos, required Preferencias prefs})
      : ajustes = EstadoAjustes(prefs),
        galeria = _crearGaleria(RepositorioMultimediaImpl(db, archivos));

  final AlmacenArchivos archivos;
  final EstadoAjustes ajustes;
  final EstadoGaleria galeria;

  static EstadoGaleria _crearGaleria(RepositorioMultimediaImpl repo) => EstadoGaleria(
        obtenerGaleria: ObtenerGaleria(repo),
        guardarFoto: GuardarFoto(repo),
        guardarAudio: GuardarAudio(repo),
        importarArchivo: ImportarArchivo(repo),
        editarFoto: EditarFoto(repo),
        actualizarMetadatos: ActualizarMetadatos(repo),
        eliminarElemento: EliminarElemento(repo),
        albumes: GestionarAlbumes(repo),
      );
}
