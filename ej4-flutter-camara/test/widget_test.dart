import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_camara/app.dart';
import 'package:flutter_camara/core/inyeccion.dart';
import 'package:flutter_camara/core/theme/tema_app.dart';
import 'package:flutter_camara/data/datasources/almacen_archivos.dart';
import 'package:flutter_camara/data/datasources/base_datos_local.dart';
import 'package:flutter_camara/data/datasources/preferencias.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'sqlite_prueba.dart';

/// Pruebas de interfaz sin teléfono: se abre la galería y los ajustes, y se
/// comprueba que los temas Guinda y Azul cambian el color principal.
void main() {
  late Dependencias deps;

  setUpAll(() async {
    iniciarSqlitePruebas();
    await initializeDateFormatting('es_MX');
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final tmp = Directory.systemTemp.createTempSync('p3_ui_');
    deps = Dependencias(
      db: await BaseDatosLocal.abrir(inMemoryDatabasePath, fabrica: databaseFactoryFfiNoIsolate),
      archivos: AlmacenArchivos(tmp),
      prefs: Preferencias(await SharedPreferences.getInstance()),
    );
  });

  tearDown(() => databaseFactoryFfiNoIsolate.deleteDatabase(inMemoryDatabasePath));

  Widget app(int pestana) =>
      AppCamara(ajustes: deps.ajustes, galeria: deps.galeria, archivos: deps.archivos, pestanaInicial: pestana);

  testWidgets('la galería vacía muestra un aviso y los álbumes', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(app(2));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    expect(find.text('Aún no hay fotos'), findsOneWidget);
    expect(find.text('General'), findsOneWidget);

    await tester.tap(find.text('Audios'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay grabaciones'), findsOneWidget);
  });

  testWidgets('cambiar a tema Azul ESCOM cambia el color primario', (tester) async {
    await tester.pumpWidget(app(3));
    await tester.pumpAndSettle();

    ColorScheme esquema() => Theme.of(tester.element(find.text('Ajustes').first)).colorScheme;
    expect(esquema().primary, PaletaApp.guinda.color);

    await tester.tap(find.text('Azul ESCOM'));
    await tester.pumpAndSettle();
    expect(esquema().primary, PaletaApp.azul.color);
    expect(deps.ajustes.paleta, PaletaApp.azul);
  });

  testWidgets('la barra de navegación tiene las cuatro secciones', (tester) async {
    await tester.pumpWidget(app(3));
    await tester.pumpAndSettle();
    for (final t in ['Cámara', 'Audio', 'Galería', 'Ajustes']) {
      expect(find.widgetWithText(NavigationDestination, t), findsOneWidget);
    }
  });

  testWidgets('los temas oscuros se generan para ambas paletas', (tester) async {
    for (final p in PaletaApp.values) {
      final oscuro = crearTema(p, Brightness.dark);
      expect(oscuro.colorScheme.brightness, Brightness.dark);
    }
  });
}
