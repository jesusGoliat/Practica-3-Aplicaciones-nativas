/// Tipo de contenido capturado.
enum TipoMultimedia { foto, audio }

/// Entidad de dominio: una foto o grabación guardada en el dispositivo junto
/// con sus metadatos. No depende de Flutter ni de la base de datos.
class ElementoMultimedia {
  const ElementoMultimedia({
    this.id,
    required this.tipo,
    required this.ruta,
    this.rutaMiniatura,
    required this.fecha,
    this.album = albumGeneral,
    this.etiquetas = const [],
    this.filtro,
    this.duracionMs,
  });

  static const albumGeneral = 'General';

  final int? id;
  final TipoMultimedia tipo;

  /// Ruta absoluta del archivo dentro del almacenamiento de la app.
  final String ruta;

  /// Miniatura reducida (solo fotos) para que la galería cargue rápido.
  final String? rutaMiniatura;
  final DateTime fecha;
  final String album;
  final List<String> etiquetas;

  /// Nombre del filtro aplicado al capturar o editar (solo fotos).
  final String? filtro;

  /// Duración de la grabación (solo audio).
  final int? duracionMs;

  ElementoMultimedia copyWith({
    int? id,
    String? ruta,
    String? rutaMiniatura,
    String? album,
    List<String>? etiquetas,
    String? filtro,
    int? duracionMs,
  }) {
    return ElementoMultimedia(
      id: id ?? this.id,
      tipo: tipo,
      ruta: ruta ?? this.ruta,
      rutaMiniatura: rutaMiniatura ?? this.rutaMiniatura,
      fecha: fecha,
      album: album ?? this.album,
      etiquetas: etiquetas ?? this.etiquetas,
      filtro: filtro ?? this.filtro,
      duracionMs: duracionMs ?? this.duracionMs,
    );
  }
}
