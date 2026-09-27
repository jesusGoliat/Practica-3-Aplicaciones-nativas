import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/elemento_multimedia.dart';
import '../providers/estado_galeria.dart';
import '../widgets/hoja_metadatos.dart';
import '../widgets/permisos.dart';
import 'pantalla_foto.dart';
import 'reproductor_audio.dart';

/// Galería integrada: fotos en cuadrícula y audios en lista, filtrables por
/// álbum. Permite importar archivos y crear álbumes.
class PantallaGaleria extends StatefulWidget {
  const PantallaGaleria({super.key});

  @override
  State<PantallaGaleria> createState() => _PantallaGaleriaState();
}

class _PantallaGaleriaState extends State<PantallaGaleria> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<EstadoGaleria>().cargar();
    });
  }

  Future<void> _importar() async {
    try {
      final r = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'm4a', 'aac', 'mp3', 'wav'],
        allowMultiple: true,
      );
      if (r == null || !mounted) return;
      final galeria = context.read<EstadoGaleria>();
      var importados = 0;
      for (final f in r.files) {
        if (f.path == null) continue;
        await galeria.importar(f.path!);
        importados++;
      }
      if (mounted) mostrarMensaje(context, '$importados archivo(s) importado(s).');
    } on FormatException catch (e) {
      if (mounted) mostrarMensaje(context, e.message);
    } catch (e) {
      if (mounted) mostrarMensaje(context, 'No se pudo importar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = context.watch<EstadoGaleria>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Galería'),
        actions: [
          IconButton(tooltip: 'Importar archivos', icon: const Icon(Icons.file_download_outlined), onPressed: _importar),
          IconButton(tooltip: 'Nuevo álbum', icon: const Icon(Icons.create_new_folder_outlined), onPressed: () => crearAlbum(context)),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedButton<TipoMultimedia>(
              segments: const [
                ButtonSegment(value: TipoMultimedia.foto, label: Text('Fotos'), icon: Icon(Icons.photo)),
                ButtonSegment(value: TipoMultimedia.audio, label: Text('Audios'), icon: Icon(Icons.graphic_eq)),
              ],
              selected: {g.tipo},
              onSelectionChanged: (s) => g.cambiarTipo(s.first),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _chip(g, null, 'Todos'),
                for (final a in g.listaAlbumes) _chip(g, a, a),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: g.cargar,
              child: g.error != null
                  ? ListView(children: [AvisoRecurso(icono: Icons.error_outline, titulo: 'Error', mensaje: g.error!)])
                  : g.elementos.isEmpty && !g.cargando
                      ? ListView(children: [
                          AvisoRecurso(
                            icono: g.tipo == TipoMultimedia.foto ? Icons.photo_outlined : Icons.mic_none,
                            titulo: 'Aún no hay ${g.tipo == TipoMultimedia.foto ? 'fotos' : 'grabaciones'}',
                            mensaje: 'Captura algo o importa archivos desde el dispositivo.',
                          ),
                        ])
                      : g.tipo == TipoMultimedia.foto
                          ? _cuadricula(g.elementos)
                          : _listaAudios(g.elementos),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(EstadoGaleria g, String? album, String texto) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FilterChip(
          label: Text(texto),
          selected: g.albumSeleccionado == album,
          onSelected: (_) => g.filtrarAlbum(album),
        ),
      );

  Widget _cuadricula(List<ElementoMultimedia> fotos) {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 140, mainAxisSpacing: 4, crossAxisSpacing: 4),
      itemCount: fotos.length,
      itemBuilder: (context, i) {
        final f = fotos[i];
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaFoto(foto: f))),
          child: Hero(
            tag: 'foto-${f.id}',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              // Se usa la miniatura en caché, decodificada al tamaño de la celda.
              child: Image.file(
                File(f.rutaMiniatura ?? f.ruta),
                key: ValueKey('${f.id}-${f.filtro}'),
                fit: BoxFit.cover,
                cacheWidth: 280,
                errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black12, child: Icon(Icons.broken_image)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _listaAudios(List<ElementoMultimedia> audios) {
    final fecha = DateFormat('d MMM yyyy, HH:mm', 'es_MX');
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: audios.length,
      itemBuilder: (context, i) {
        final a = audios[i];
        final d = Duration(milliseconds: a.duracionMs ?? 0);
        return Dismissible(
          key: ValueKey(a.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Theme.of(context).colorScheme.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
          ),
          confirmDismiss: (_) => confirmarEliminar(context),
          onDismissed: (_) => context.read<EstadoGaleria>().eliminar(a),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.graphic_eq)),
            title: Text(fecha.format(a.fecha)),
            subtitle: Text([
              '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}',
              a.album,
              ...a.etiquetas.map((t) => '#$t'),
            ].join(' · ')),
            trailing: IconButton(
              tooltip: 'Álbum y etiquetas',
              icon: const Icon(Icons.sell_outlined),
              onPressed: () => editarMetadatos(context, a),
            ),
            onTap: () => mostrarReproductor(context, a),
          ),
        );
      },
    );
  }
}
