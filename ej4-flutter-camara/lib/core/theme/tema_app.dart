import 'package:flutter/material.dart';

/// Temas personalizables que pide la práctica.
enum PaletaApp {
  guinda('Guinda IPN', Color(0xFF6C1D45)),
  azul('Azul ESCOM', Color(0xFF003B5C));

  const PaletaApp(this.nombre, this.color);

  final String nombre;
  final Color color;
}

/// Construye un [ThemeData] de Material 3 a partir de la paleta y del brillo
/// (claro u oscuro) que marque el sistema.
ThemeData crearTema(PaletaApp paleta, Brightness brillo) {
  final base = ColorScheme.fromSeed(seedColor: paleta.color, brightness: brillo);
  // En modo claro se fuerza el color institucional exacto; en oscuro se deja
  // el tono claro que calcula Material 3 para conservar el contraste.
  final esquema = brillo == Brightness.light
      ? base.copyWith(primary: paleta.color, onPrimary: Colors.white)
      : base;

  return ThemeData(
    useMaterial3: true,
    colorScheme: esquema,
    appBarTheme: AppBarTheme(
      backgroundColor: brillo == Brightness.light ? paleta.color : esquema.surface,
      foregroundColor: brillo == Brightness.light ? Colors.white : esquema.onSurface,
      centerTitle: true,
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: esquema.primaryContainer,
    ),
  );
}
