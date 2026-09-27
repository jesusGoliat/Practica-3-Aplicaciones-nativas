import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/elemento_multimedia.dart';
import '../providers/estado_galeria.dart';

/// Hoja inferior para cambiar el álbum y las etiquetas de un elemento.
Future<void> editarMetadatos(BuildContext context, ElementoMultimedia elemento) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => ChangeNotifierProvider.value(
      value: context.read<EstadoGaleria>(),
      child: _HojaMetadatos(elemento: elemento),
    ),
  );
}

class _HojaMetadatos extends StatefulWidget {
  const _HojaMetadatos({required this.elemento});

  final ElementoMultimedia elemento;

  @override
  State<_HojaMetadatos> createState() => _HojaMetadatosState();
}

class _HojaMetadatosState extends State<_HojaMetadatos> {
  late String _album = widget.elemento.album;
  late final _etiquetas = TextEditingController(text: widget.elemento.etiquetas.join(', '));

  @override
  void dispose() {
    _etiquetas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final galeria = context.watch<EstadoGaleria>();
    final albumes = {...galeria.listaAlbumes, _album}.toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Álbum y etiquetas', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _album,
            decoration: const InputDecoration(labelText: 'Álbum', border: OutlineInputBorder()),
            items: [for (final a in albumes) DropdownMenuItem(value: a, child: Text(a))],
            onChanged: (v) => setState(() => _album = v ?? _album),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _etiquetas,
            decoration: const InputDecoration(
              labelText: 'Etiquetas',
              helperText: 'Separadas por comas, por ejemplo: escuela, práctica',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final etiquetas = _etiquetas.text
                  .split(',')
                  .map((t) => t.trim())
                  .where((t) => t.isNotEmpty)
                  .toList();
              await galeria.guardarMetadatos(widget.elemento.copyWith(album: _album, etiquetas: etiquetas));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

/// Diálogo para crear un álbum nuevo.
Future<void> crearAlbum(BuildContext context) async {
  final control = TextEditingController();
  final nombre = await showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Nuevo álbum'),
      content: TextField(
        controller: control,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Nombre'),
        onSubmitted: (v) => Navigator.pop(c, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(c, control.text), child: const Text('Crear')),
      ],
    ),
  );
  control.dispose();
  if (nombre != null && context.mounted) await context.read<EstadoGaleria>().crearAlbum(nombre);
}

/// Confirmación antes de borrar.
Future<bool> confirmarEliminar(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      icon: const Icon(Icons.delete_outline),
      title: const Text('¿Eliminar?'),
      content: const Text('El archivo se borrará del dispositivo. Esta acción no se puede deshacer.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Eliminar')),
      ],
    ),
  );
  return ok ?? false;
}
