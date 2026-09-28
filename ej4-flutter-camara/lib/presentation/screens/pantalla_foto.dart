import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/elemento_multimedia.dart';
import '../../domain/entities/filtro_foto.dart';
import '../providers/estado_galeria.dart';
import '../widgets/hoja_metadatos.dart';
import '../widgets/permisos.dart';

/// Visor de una foto con zoom (pellizcar) y acciones: editar, etiquetar,
/// compartir/exportar y eliminar.
class PantallaFoto extends StatefulWidget {
  const PantallaFoto({super.key, required this.foto});

  final ElementoMultimedia foto;

  @override
  State<PantallaFoto> createState() => _PantallaFotoState();
}

class _PantallaFotoState extends State<PantallaFoto> {
  late ElementoMultimedia _foto = widget.foto;
  int _version = 0;

  ElementoMultimedia get _actual =>
      context.watch<EstadoGaleria>().elementos.firstWhere((e) => e.id == _foto.id, orElse: () => _foto);

  Future<void> _editar() async {
    final cambio = await Navigator.push<(FiltroFoto, int)>(
      context,
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => _EditorFoto(foto: _foto)),
    );
    if (cambio == null || !mounted) return;
    final (filtro, giro) = cambio;
    final editada = await context.read<EstadoGaleria>().editar(_foto, filtro: filtro, giro: giro);
    // El archivo cambió en el disco: se descarta la versión en caché.
    await FileImage(File(editada.ruta)).evict();
    if (editada.rutaMiniatura != null) await FileImage(File(editada.rutaMiniatura!)).evict();
    imageCache.clear();
    setState(() {
      _foto = editada;
      _version++;
    });
  }

  Future<void> _eliminar() async {
    final galeria = context.read<EstadoGaleria>();
    if (!await confirmarEliminar(context)) return;
    await galeria.eliminar(_foto);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final foto = _actual;
    final fecha = DateFormat("d 'de' MMMM 'de' yyyy, HH:mm", 'es_MX').format(foto.fecha);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Foto'),
        actions: [
          IconButton(tooltip: 'Editar', icon: const Icon(Icons.tune), onPressed: _editar),
          IconButton(
            tooltip: 'Compartir / exportar',
            icon: const Icon(Icons.ios_share),
            onPressed: () => Share.shareXFiles([XFile(foto.ruta)], text: 'Foto de la Práctica 3'),
          ),
          IconButton(tooltip: 'Eliminar', icon: const Icon(Icons.delete_outline), onPressed: _eliminar),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(
                child: Hero(
                  tag: 'foto-${foto.id}',
                  child: Image.file(
                    File(foto.ruta),
                    key: ValueKey(_version),
                    errorBuilder: (_, __, ___) => const AvisoRecurso(
                      icono: Icons.broken_image_outlined,
                      titulo: 'Archivo no disponible',
                      mensaje: 'La imagen está dañada o fue eliminada.',
                    ),
                  ),
                ),
              ),
            ),
          ),
          Material(
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(fecha),
              subtitle: Text([
                'Álbum: ${foto.album}',
                'Filtro: ${FiltroFoto.porNombre(foto.filtro).nombre}',
                if (foto.etiquetas.isNotEmpty) foto.etiquetas.map((t) => '#$t').join(' '),
              ].join('\n')),
              isThreeLine: true,
              trailing: IconButton(
                tooltip: 'Álbum y etiquetas',
                icon: const Icon(Icons.sell_outlined),
                onPressed: () => editarMetadatos(context, foto),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Edición básica: girar en pasos de 90° y aplicar un filtro de color.
/// La vista previa se hace con widgets; el cambio real se aplica al guardar.
class _EditorFoto extends StatefulWidget {
  const _EditorFoto({required this.foto});

  final ElementoMultimedia foto;

  @override
  State<_EditorFoto> createState() => _EditorFotoState();
}

class _EditorFotoState extends State<_EditorFoto> {
  int _cuartos = 0;
  FiltroFoto _filtro = FiltroFoto.ninguno;

  @override
  Widget build(BuildContext context) {
    Widget imagen = Image.file(File(widget.foto.ruta));
    if (_filtro.matriz != null) imagen = ColorFiltered(colorFilter: ColorFilter.matrix(_filtro.matriz!), child: imagen);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, (_filtro, (_cuartos % 4) * 90)),
            child: Text('Guardar', style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              // RotatedBox vuelve a medir la imagen al girarla, así una foto
              // vertical girada 90° cabe completa en pantalla (AnimatedRotation
              // solo la dibujaba girada y se salía por los lados).
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: RotatedBox(key: ValueKey(_cuartos % 4), quarterTurns: _cuartos % 4, child: imagen),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                tooltip: 'Girar a la izquierda',
                icon: const Icon(Icons.rotate_left),
                onPressed: () => setState(() => _cuartos--),
              ),
              const SizedBox(width: 16),
              IconButton.filledTonal(
                tooltip: 'Girar a la derecha',
                icon: const Icon(Icons.rotate_right),
                onPressed: () => setState(() => _cuartos++),
              ),
            ],
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
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
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
