import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';

import '../../data/datasources/almacen_archivos.dart';
import '../providers/estado_ajustes.dart';
import '../providers/estado_galeria.dart';
import '../widgets/permisos.dart';

/// Grabadora de audio con medidor de nivel, sensibilidad configurable y
/// temporizador de grabación (se detiene sola al llegar al límite).
class PantallaAudio extends StatefulWidget {
  const PantallaAudio({super.key});

  @override
  State<PantallaAudio> createState() => _PantallaAudioState();
}

enum _EstadoGrabacion { detenido, grabando, pausado }

class _PantallaAudioState extends State<PantallaAudio> {
  final _grabador = AudioRecorder();
  StreamSubscription<Amplitude>? _subNivel;
  Timer? _reloj;

  _EstadoGrabacion _estado = _EstadoGrabacion.detenido;
  Duration _transcurrido = Duration.zero;
  final List<double> _historial = [];
  double _nivel = 0;

  /// Configuración de captura según la sensibilidad elegida. "Alta" activa la
  /// ganancia automática y amplifica el medidor; "Baja" suprime ruido.
  static RecordConfig _config(String sensibilidad) => switch (sensibilidad) {
        'baja' => const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 64000, sampleRate: 22050, noiseSuppress: true, echoCancel: true),
        'alta' => const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 192000, sampleRate: 48000, autoGain: true),
        _ => const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100, autoGain: true, noiseSuppress: true),
      };

  /// Decibeles (dBFS) a partir de los cuales el medidor empieza a moverse.
  static double _umbral(String sensibilidad) => switch (sensibilidad) {
        'baja' => -35,
        'alta' => -65,
        _ => -50,
      };

  @override
  void dispose() {
    _subNivel?.cancel();
    _reloj?.cancel();
    _grabador.dispose();
    super.dispose();
  }

  Future<void> _iniciar() async {
    final ajustes = context.read<EstadoAjustes>();
    final permitido = await pedirPermiso(
      context,
      Permission.microphone,
      'El micrófono se usa para grabar notas de voz que se guardan solo en este dispositivo.',
    );
    if (!permitido || !mounted) return;

    final ruta = await context.read<AlmacenArchivos>().rutaGrabacionNueva();
    try {
      await _grabador.start(_config(ajustes.sensibilidad), path: ruta);
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudo iniciar la grabación: $e');
      return;
    }

    final umbral = _umbral(ajustes.sensibilidad);
    _subNivel = _grabador.onAmplitudeChanged(const Duration(milliseconds: 100)).listen((a) {
      // Normaliza dBFS [umbral, 0] a [0, 1].
      final n = ((a.current - umbral) / -umbral).clamp(0.0, 1.0);
      setState(() {
        _nivel = n;
        _historial.add(n);
        if (_historial.length > 60) _historial.removeAt(0);
      });
    });

    _transcurrido = Duration.zero;
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_estado != _EstadoGrabacion.grabando) return;
      setState(() => _transcurrido += const Duration(seconds: 1));
      final limite = ajustes.limiteAudio;
      if (limite > 0 && _transcurrido.inSeconds >= limite) _detener();
    });
    setState(() => _estado = _EstadoGrabacion.grabando);
  }

  Future<void> _pausarReanudar() async {
    if (_estado == _EstadoGrabacion.grabando) {
      await _grabador.pause();
      setState(() => _estado = _EstadoGrabacion.pausado);
    } else {
      await _grabador.resume();
      setState(() => _estado = _EstadoGrabacion.grabando);
    }
  }

  Future<void> _detener() async {
    _reloj?.cancel();
    await _subNivel?.cancel();
    final ruta = await _grabador.stop();
    final duracion = _transcurrido;
    setState(() {
      _estado = _EstadoGrabacion.detenido;
      _nivel = 0;
      _historial.clear();
    });
    if (ruta == null || !mounted) return;
    await context.read<EstadoGaleria>().agregarAudio(ruta, duracion.inMilliseconds);
    if (mounted) mostrarMensaje(context, 'Grabación guardada (${_formato(duracion)}).');
  }

  static String _formato(Duration d) =>
      '${d.inMinutes.toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final ajustes = context.watch<EstadoAjustes>();
    final esquema = Theme.of(context).colorScheme;
    final activo = _estado != _EstadoGrabacion.detenido;

    return Scaffold(
      appBar: AppBar(title: const Text('Grabadora')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _formato(_transcurrido),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          if (ajustes.limiteAudio > 0)
            Text('Límite: ${_formato(Duration(seconds: ajustes.limiteAudio))}', textAlign: TextAlign.center),
          const SizedBox(height: 24),
          // Medidor de nivel: círculo que crece con la voz + historial en barras.
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 120 + 80 * _nivel,
              height: 120 + 80 * _nivel,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: esquema.primary.withOpacity(0.15 + 0.35 * _nivel),
              ),
              child: Icon(activo ? Icons.mic : Icons.mic_none, size: 64, color: esquema.primary),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 60, child: CustomPaint(painter: _Onda(_historial, esquema.primary))),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (activo)
                IconButton.filledTonal(
                  iconSize: 32,
                  tooltip: _estado == _EstadoGrabacion.pausado ? 'Reanudar' : 'Pausar',
                  icon: Icon(_estado == _EstadoGrabacion.pausado ? Icons.play_arrow : Icons.pause),
                  onPressed: _pausarReanudar,
                ),
              const SizedBox(width: 24),
              FloatingActionButton.large(
                heroTag: 'grabar',
                tooltip: activo ? 'Detener y guardar' : 'Grabar',
                onPressed: activo ? _detener : _iniciar,
                child: Icon(activo ? Icons.stop : Icons.fiber_manual_record),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text('Sensibilidad del micrófono', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'baja', label: Text('Baja'), icon: Icon(Icons.volume_mute)),
              ButtonSegment(value: 'media', label: Text('Media'), icon: Icon(Icons.volume_down)),
              ButtonSegment(value: 'alta', label: Text('Alta'), icon: Icon(Icons.volume_up)),
            ],
            selected: {ajustes.sensibilidad},
            onSelectionChanged: activo ? null : (s) => ajustes.cambiarSensibilidad(s.first),
          ),
          const SizedBox(height: 16),
          Text('Temporizador de grabación', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Sin límite')),
              ButtonSegment(value: 15, label: Text('15 s')),
              ButtonSegment(value: 30, label: Text('30 s')),
              ButtonSegment(value: 60, label: Text('60 s')),
            ],
            selected: {ajustes.limiteAudio},
            onSelectionChanged: activo ? null : (s) => ajustes.cambiarLimiteAudio(s.first),
          ),
        ],
      ),
    );
  }
}

/// Dibuja el historial de niveles como barras verticales simétricas.
class _Onda extends CustomPainter {
  _Onda(this.niveles, this.color);

  final List<double> niveles;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final pincel = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const maxBarras = 60;
    final paso = size.width / maxBarras;
    for (var i = 0; i < niveles.length; i++) {
      final x = size.width - (niveles.length - i) * paso;
      final alto = math.max(2.0, niveles[i] * size.height);
      canvas.drawLine(Offset(x, (size.height - alto) / 2), Offset(x, (size.height + alto) / 2), pincel);
    }
  }

  @override
  bool shouldRepaint(_Onda old) => true;
}
