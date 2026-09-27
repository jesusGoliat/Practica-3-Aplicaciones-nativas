import '../../domain/entities/elemento_multimedia.dart';

/// Conversión entre la entidad de dominio y una fila de la tabla `multimedia`.
class ElementoModelo {
  static Map<String, Object?> aFila(ElementoMultimedia e) => {
        if (e.id != null) 'id': e.id,
        'tipo': e.tipo.name,
        'ruta': e.ruta,
        'miniatura': e.rutaMiniatura,
        'fecha': e.fecha.millisecondsSinceEpoch,
        'album': e.album,
        // Las etiquetas se guardan separadas por comas para no requerir otra tabla.
        'etiquetas': e.etiquetas.join(','),
        'filtro': e.filtro,
        'duracion_ms': e.duracionMs,
      };

  static ElementoMultimedia deFila(Map<String, Object?> f) => ElementoMultimedia(
        id: f['id'] as int?,
        tipo: TipoMultimedia.values.byName(f['tipo'] as String),
        ruta: f['ruta'] as String,
        rutaMiniatura: f['miniatura'] as String?,
        fecha: DateTime.fromMillisecondsSinceEpoch(f['fecha'] as int),
        album: f['album'] as String? ?? ElementoMultimedia.albumGeneral,
        etiquetas: ((f['etiquetas'] as String?) ?? '')
            .split(',')
            .where((t) => t.trim().isNotEmpty)
            .toList(),
        filtro: f['filtro'] as String?,
        duracionMs: f['duracion_ms'] as int?,
      );
}
