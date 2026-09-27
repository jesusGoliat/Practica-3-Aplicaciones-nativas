import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/filtro_foto.dart';
import '../providers/estado_galeria.dart';
import '../widgets/permisos.dart';

/// Captura de fotos con vista previa, filtros, flash y temporizador.
/// Si el dispositivo no tiene cámara (simulador de iOS) ofrece elegir una
/// imagen de la fototeca como fuente alternativa.
class PantallaCamara extends StatefulWidget {
  const PantallaCamara({super.key});

  @override
  State<PantallaCamara> createState() => _PantallaCamaraState();
}

enum _Situacion { cargando, sinPermiso, sinCamara, lista }

class _PantallaCamaraState extends State<PantallaCamara> with WidgetsBindingObserver {
  CameraController? _control;
  List<CameraDescription> _camaras = [];
  int _indiceCamara = 0;
  _Situacion _situacion = _Situacion.cargando;

  FiltroFoto _filtro = FiltroFoto.ninguno;
  FlashMode _flash = FlashMode.off;
  int _temporizador = 0;
  int? _cuentaRegresiva;
  bool _capturando = false;

  static const _opcionesTemporizador = [0, 3, 5, 10];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _iniciar());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _control?.dispose();
    super.dispose();
  }

  // La cámara se libera al salir de la app y se reabre al volver.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _control;
    if (c == null || !c.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      c.dispose();
      _control = null;
    } else if (state == AppLifecycleState.resumed) {
      _abrirCamara();
    }
  }

  Future<void> _iniciar() async {
    final permitido = await pedirPermiso(
      context,
      Permission.camera,
      'La cámara se usa para tomar fotos que se guardan solo en este dispositivo.',
    );
    if (!permitido) {
      // Sin permiso puede ser también que no exista cámara (simulador).
      await _buscarCamaras();
      if (mounted && _situacion != _Situacion.sinCamara) setState(() => _situacion = _Situacion.sinPermiso);
      return;
    }
    await _buscarCamaras();
    if (_camaras.isNotEmpty) await _abrirCamara();
  }

  Future<void> _buscarCamaras() async {
    try {
      _camaras = await availableCameras();
    } catch (_) {
      _camaras = [];
    }
    if (_camaras.isEmpty && mounted) setState(() => _situacion = _Situacion.sinCamara);
  }

  Future<void> _abrirCamara() async {
    final anterior = _control;
    _control = null;
    await anterior?.dispose();
    final c = CameraController(_camaras[_indiceCamara], ResolutionPreset.high, enableAudio: false);
    try {
      await c.initialize();
      await c.setFlashMode(_flash);
      if (!mounted) return;
      setState(() {
        _control = c;
        _situacion = _Situacion.lista;
      });
    } on CameraException catch (e) {
      if (mounted) {
        setState(() => _situacion = e.code == 'CameraAccessDenied' ? _Situacion.sinPermiso : _Situacion.sinCamara);
      }
    }
  }

  Future<void> _cambiarFlash() async {
    const ciclo = [FlashMode.off, FlashMode.auto, FlashMode.always, FlashMode.torch];
    final siguiente = ciclo[(ciclo.indexOf(_flash) + 1) % ciclo.length];
    try {
      await _control?.setFlashMode(siguiente);
      setState(() => _flash = siguiente);
    } on CameraException {
      if (mounted) mostrarMensaje(context, 'Esta cámara no tiene flash.');
    }
  }

  void _cambiarTemporizador() {
    final i = _opcionesTemporizador.indexOf(_temporizador);
    setState(() => _temporizador = _opcionesTemporizador[(i + 1) % _opcionesTemporizador.length]);
  }

  Future<void> _voltearCamara() async {
    if (_camaras.length < 2) return;
    _indiceCamara = (_indiceCamara + 1) % _camaras.length;
    await _abrirCamara();
  }

  Future<void> _disparar() async {
    final c = _control;
    if (c == null || _capturando) return;
    setState(() => _capturando = true);

    // Cuenta regresiva del temporizador.
    for (var s = _temporizador; s > 0; s--) {
      setState(() => _cuentaRegresiva = s);
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted) return;
    }
    setState(() => _cuentaRegresiva = null);

    try {
      final foto = await c.takePicture();
      if (!mounted) return;
      await context.read<EstadoGaleria>().agregarFoto(foto.path, _filtro);
      if (mounted) mostrarMensaje(context, 'Foto guardada en la galería (${_filtro.nombre}).');
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudo tomar la foto: $e');
    } finally {
      if (mounted) setState(() => _capturando = false);
    }
  }

  /// Fuente alternativa: fototeca (necesaria en el simulador de iOS).
  Future<void> _elegirDeFototeca() async {
    try {
      final x = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (x == null || !mounted) return;
      await context.read<EstadoGaleria>().agregarFoto(x.path, _filtro);
      if (mounted) mostrarMensaje(context, 'Imagen importada con filtro ${_filtro.nombre}.');
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudo abrir la fototeca: $e');
    }
  }

  IconData get _iconoFlash => switch (_flash) {
        FlashMode.off => Icons.flash_off,
        FlashMode.auto => Icons.flash_auto,
        FlashMode.always => Icons.flash_on,
        FlashMode.torch => Icons.highlight,
      };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cámara'),
        actions: [
          IconButton(
            tooltip: 'Elegir de la fototeca',
            icon: const Icon(Icons.photo_library_outlined),
            onPressed: _elegirDeFototeca,
          ),
        ],
      ),
      body: switch (_situacion) {
        _Situacion.cargando => const Center(child: CircularProgressIndicator()),
        _Situacion.sinPermiso => AvisoRecurso(
            icono: Icons.no_photography_outlined,
            titulo: 'Sin permiso de cámara',
            mensaje: 'Concede el permiso para tomar fotos o importa una imagen de la fototeca.',
            acciones: [
              FilledButton(onPressed: _iniciar, child: const Text('Reintentar')),
              OutlinedButton(onPressed: _elegirDeFototeca, child: const Text('Fototeca')),
            ],
          ),
        _Situacion.sinCamara => AvisoRecurso(
            icono: Icons.videocam_off_outlined,
            titulo: 'Este dispositivo no tiene cámara',
            mensaje: 'El simulador de iPhone no tiene cámara física. '
                'Usa la fototeca como fuente alternativa; el filtro elegido se aplica igual.',
            acciones: [
              FilledButton.icon(
                onPressed: _elegirDeFototeca,
                icon: const Icon(Icons.photo_library),
                label: const Text('Elegir de la fototeca'),
              ),
              _selectorFiltros(),
            ],
          ),
        _Situacion.lista => _vistaCamara(),
      },
    );
  }

  Widget _vistaCamara() {
    final c = _control;
    if (c == null || !c.value.isInitialized) return const Center(child: CircularProgressIndicator());
    final matriz = _filtro.matriz;
    Widget vista = CameraPreview(c);
    if (matriz != null) vista = ColorFiltered(colorFilter: ColorFilter.matrix(matriz), child: vista);

    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(child: AspectRatio(aspectRatio: 1 / c.value.aspectRatio, child: vista)),
              // Número animado de la cuenta regresiva.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (w, a) => ScaleTransition(scale: a, child: w),
                child: _cuentaRegresiva == null
                    ? const SizedBox.shrink()
                    : Text(
                        '$_cuentaRegresiva',
                        key: ValueKey(_cuentaRegresiva),
                        style: const TextStyle(fontSize: 96, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
        _selectorFiltros(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton.filledTonal(tooltip: 'Flash', icon: Icon(_iconoFlash), onPressed: _cambiarFlash),
              IconButton.filledTonal(
                tooltip: 'Temporizador',
                icon: Badge(
                  isLabelVisible: _temporizador > 0,
                  label: Text('${_temporizador}s'),
                  child: const Icon(Icons.timer_outlined),
                ),
                onPressed: _cambiarTemporizador,
              ),
              _BotonDisparo(ocupado: _capturando, onPressed: _disparar),
              IconButton.filledTonal(
                tooltip: 'Cambiar cámara',
                icon: const Icon(Icons.cameraswitch_outlined),
                onPressed: _camaras.length > 1 ? _voltearCamara : null,
              ),
              IconButton.filledTonal(
                tooltip: 'Fototeca',
                icon: const Icon(Icons.photo_library_outlined),
                onPressed: _elegirDeFototeca,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _selectorFiltros() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        children: [
          for (final f in FiltroFoto.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(f.nombre),
                selected: f == _filtro,
                onSelected: (_) => setState(() => _filtro = f),
              ),
            ),
        ],
      ),
    );
  }
}

/// Botón de disparo con animación de pulsación.
class _BotonDisparo extends StatefulWidget {
  const _BotonDisparo({required this.ocupado, required this.onPressed});

  final bool ocupado;
  final VoidCallback onPressed;

  @override
  State<_BotonDisparo> createState() => _BotonDisparoState();
}

class _BotonDisparoState extends State<_BotonDisparo> {
  bool _presionado = false;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      label: 'Tomar foto',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _presionado = true),
        onTapCancel: () => setState(() => _presionado = false),
        onTapUp: (_) {
          setState(() => _presionado = false);
          if (!widget.ocupado) widget.onPressed();
        },
        child: AnimatedScale(
          scale: _presionado ? 0.85 : 1,
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 4),
            ),
            padding: const EdgeInsets.all(4),
            child: DecoratedBox(
              decoration: BoxDecoration(shape: BoxShape.circle, color: widget.ocupado ? Colors.grey : color),
            ),
          ),
        ),
      ),
    );
  }
}
