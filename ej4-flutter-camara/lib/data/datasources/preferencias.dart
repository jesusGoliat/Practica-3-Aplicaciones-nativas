import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/tema_app.dart';

/// Preferencias del usuario (tema y opciones de captura) en SharedPreferences
/// (UserDefaults en iOS, SharedPreferences en Android).
class Preferencias {
  Preferencias(this._prefs);

  final SharedPreferences _prefs;

  PaletaApp get paleta => PaletaApp.values.firstWhere(
        (p) => p.name == _prefs.getString('paleta'),
        orElse: () => PaletaApp.guinda,
      );
  set paleta(PaletaApp v) => _prefs.setString('paleta', v.name);

  /// 0 = seguir al sistema, 1 = claro, 2 = oscuro.
  int get modo => _prefs.getInt('modo') ?? 0;
  set modo(int v) => _prefs.setInt('modo', v);

  String get sensibilidad => _prefs.getString('sensibilidad') ?? 'media';
  set sensibilidad(String v) => _prefs.setString('sensibilidad', v);

  /// Límite de grabación en segundos (0 = sin límite).
  int get limiteAudio => _prefs.getInt('limiteAudio') ?? 0;
  set limiteAudio(int v) => _prefs.setInt('limiteAudio', v);
}
