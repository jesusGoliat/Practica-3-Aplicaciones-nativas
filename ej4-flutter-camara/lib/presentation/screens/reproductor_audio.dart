import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/elemento_multimedia.dart';
import '../providers/estado_galeria.dart';
import '../widgets/hoja_metadatos.dart';

/// Abre el reproductor como hoja inferior.
Future<void> mostrarReproductor(BuildContext context, ElementoMultimedia audio) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<EstadoGaleria>(),
      child: ReproductorAudio(audio: audio),
    ),
  );
}

/// Reproductor de grabaciones con barra de avance, compartir y eliminar.
class ReproductorAudio extends StatefulWidget {
  const ReproductorAudio({super.key, required this.audio});

  final ElementoMultimedia audio;

  @override
  State<ReproductorAudio> createState() => _ReproductorAudioState();
}

class _ReproductorAudioState extends State<ReproductorAudio> {
  final _jugador = AudioPlayer();
  final _subs = <StreamSubscription<Object?>>[];
  Duration _posicion = Duration.zero;
  Duration _duracion = Duration.zero;
  bool _sonando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subs
      ..add(_jugador.onPositionChanged.listen((p) => setState(() => _posicion = p)))
      ..add(_jugador.onDurationChanged.listen((d) => setState(() => _duracion = d)))
      ..add(_jugador.onPlayerStateChanged.listen((s) => setState(() => _sonando = s == PlayerState.playing)))
      ..add(_jugador.onPlayerComplete.listen((_) => setState(() => _posicion = Duration.zero)));
    _jugador.setSource(DeviceFileSource(widget.audio.ruta)).catchError((Object e) {
      if (mounted) setState(() => _error = 'No se puede reproducir este archivo.');
    });
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _jugador.dispose();
    super.dispose();
  }

  String _f(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final maximo = _duracion.inMilliseconds.toDouble();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Reproductor', style: Theme.of(context).textTheme.titleLarge),
          if (_error != null) Padding(padding: const EdgeInsets.all(8), child: Text(_error!)),
          Slider(
            value: _posicion.inMilliseconds.clamp(0, maximo).toDouble(),
            max: maximo > 0 ? maximo : 1,
            onChanged: maximo > 0 ? (v) => _jugador.seek(Duration(milliseconds: v.round())) : null,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text(_f(_posicion)), Text(_f(_duracion))],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                tooltip: 'Compartir / exportar',
                icon: const Icon(Icons.ios_share),
                onPressed: () => Share.shareXFiles([XFile(widget.audio.ruta)]),
              ),
              IconButton.filled(
                iconSize: 40,
                tooltip: _sonando ? 'Pausar' : 'Reproducir',
                icon: Icon(_sonando ? Icons.pause : Icons.play_arrow),
                onPressed: _error != null ? null : () => _sonando ? _jugador.pause() : _jugador.resume(),
              ),
              IconButton(
                tooltip: 'Álbum y etiquetas',
                icon: const Icon(Icons.sell_outlined),
                onPressed: () => editarMetadatos(context, widget.audio),
              ),
              IconButton(
                tooltip: 'Eliminar',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  if (!await confirmarEliminar(context) || !context.mounted) return;
                  await _jugador.stop();
                  if (!context.mounted) return;
                  await context.read<EstadoGaleria>().eliminar(widget.audio);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
