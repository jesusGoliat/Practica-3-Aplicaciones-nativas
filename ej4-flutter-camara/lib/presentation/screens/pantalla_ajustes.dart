import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/tema_app.dart';
import '../providers/estado_ajustes.dart';

/// Selección de tema (Guinda IPN / Azul ESCOM) y de modo claro/oscuro.
class PantallaAjustes extends StatelessWidget {
  const PantallaAjustes({super.key});

  @override
  Widget build(BuildContext context) {
    final ajustes = context.watch<EstadoAjustes>();
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          const _Titulo('Tema'),
          for (final p in PaletaApp.values)
            RadioListTile<PaletaApp>(
              value: p,
              groupValue: ajustes.paleta,
              onChanged: (v) => ajustes.cambiarPaleta(v!),
              title: Text(p.nombre),
              secondary: CircleAvatar(backgroundColor: p.color),
            ),
          const _Titulo('Apariencia'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('Sistema'), icon: Icon(Icons.brightness_auto)),
                ButtonSegment(value: ThemeMode.light, label: Text('Claro'), icon: Icon(Icons.light_mode)),
                ButtonSegment(value: ThemeMode.dark, label: Text('Oscuro'), icon: Icon(Icons.dark_mode)),
              ],
              selected: {ajustes.modo},
              onSelectionChanged: (s) => ajustes.cambiarModo(s.first),
            ),
          ),
          const _Titulo('Almacenamiento'),
          const ListTile(
            leading: Icon(Icons.cloud_off),
            title: Text('Funciona sin conexión'),
            subtitle: Text('Fotos, audios y metadatos se guardan solo en este dispositivo (SQLite + archivos locales).'),
          ),
          const AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: 'Cámara P3',
            applicationVersion: '1.0.0',
            applicationLegalese: 'Práctica 3 — Desarrollo de aplicaciones móviles nativas, ESCOM-IPN.',
          ),
        ],
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(texto, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary)),
      );
}
