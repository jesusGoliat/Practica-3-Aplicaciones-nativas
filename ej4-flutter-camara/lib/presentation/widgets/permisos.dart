import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Pide un permiso en tiempo de ejecución. Si el usuario lo negó de forma
/// permanente, explica para qué se usa y ofrece abrir los Ajustes del sistema.
Future<bool> pedirPermiso(BuildContext context, Permission permiso, String paraQue) async {
  PermissionStatus estado;
  try {
    estado = await permiso.request();
  } catch (_) {
    // Plataformas sin el plugin (pruebas de widgets): se asume sin permiso.
    return false;
  }
  if (estado.isGranted || estado.isLimited) return true;

  if (context.mounted && (estado.isPermanentlyDenied || estado.isRestricted)) {
    final abrir = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.lock_outline),
        title: const Text('Permiso necesario'),
        content: Text('$paraQue\n\nPuedes activarlo en Ajustes del sistema.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Ahora no')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Abrir Ajustes')),
        ],
      ),
    );
    if (abrir == true) await openAppSettings();
  }
  return false;
}

/// Mensaje centrado que se muestra cuando falta un permiso o un recurso.
class AvisoRecurso extends StatelessWidget {
  const AvisoRecurso({
    super.key,
    required this.icono,
    required this.titulo,
    required this.mensaje,
    this.acciones = const [],
  });

  final IconData icono;
  final String titulo;
  final String mensaje;
  final List<Widget> acciones;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 64, color: tema.colorScheme.primary),
            const SizedBox(height: 16),
            Text(titulo, style: tema.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: acciones),
          ],
        ),
      ),
    );
  }
}

void mostrarMensaje(BuildContext context, String texto) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(texto)));
}
