import 'package:flutter/material.dart';

import '../../core/theme/tema_app.dart';
import '../../data/datasources/preferencias.dart';

/// Estado global de preferencias (Provider + ChangeNotifier).
class EstadoAjustes extends ChangeNotifier {
  EstadoAjustes(this._prefs);

  final Preferencias _prefs;

  PaletaApp get paleta => _prefs.paleta;
  ThemeMode get modo => ThemeMode.values[_prefs.modo];
  String get sensibilidad => _prefs.sensibilidad;
  int get limiteAudio => _prefs.limiteAudio;

  void cambiarPaleta(PaletaApp p) {
    _prefs.paleta = p;
    notifyListeners();
  }

  void cambiarModo(ThemeMode m) {
    _prefs.modo = m.index;
    notifyListeners();
  }

  void cambiarSensibilidad(String s) {
    _prefs.sensibilidad = s;
    notifyListeners();
  }

  void cambiarLimiteAudio(int segundos) {
    _prefs.limiteAudio = segundos;
    notifyListeners();
  }
}
