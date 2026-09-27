/// Filtros disponibles para las fotos. La matriz de color sirve tanto para la
/// vista previa en vivo (ColorFiltered) como para aplicarla al archivo final,
/// así lo que se ve es exactamente lo que se guarda.
enum FiltroFoto {
  ninguno('Original', null),
  grises('Grises', [
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]),
  sepia('Sepia', [
    0.393, 0.769, 0.189, 0, 0,
    0.349, 0.686, 0.168, 0, 0,
    0.272, 0.534, 0.131, 0, 0,
    0, 0, 0, 1, 0,
  ]),
  frio('Frío', [
    0.9, 0, 0, 0, 0,
    0, 1.0, 0, 0, 0,
    0, 0, 1.2, 0, 20,
    0, 0, 0, 1, 0,
  ]),
  calido('Cálido', [
    1.2, 0, 0, 0, 15,
    0, 1.05, 0, 0, 0,
    0, 0, 0.85, 0, 0,
    0, 0, 0, 1, 0,
  ]),
  negativo('Negativo', [
    -1, 0, 0, 0, 255,
    0, -1, 0, 0, 255,
    0, 0, -1, 0, 255,
    0, 0, 0, 1, 0,
  ]);

  const FiltroFoto(this.nombre, this.matriz);

  final String nombre;

  /// Matriz 4x5 (RGBA + desplazamiento) o null si no se aplica filtro.
  final List<double>? matriz;

  static FiltroFoto porNombre(String? nombre) =>
      FiltroFoto.values.firstWhere((f) => f.name == nombre, orElse: () => FiltroFoto.ninguno);
}
