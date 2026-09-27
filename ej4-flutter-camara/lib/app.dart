import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme/tema_app.dart';
import 'data/datasources/almacen_archivos.dart';
import 'presentation/providers/estado_ajustes.dart';
import 'presentation/providers/estado_galeria.dart';
import 'presentation/screens/pantalla_ajustes.dart';
import 'presentation/screens/pantalla_audio.dart';
import 'presentation/screens/pantalla_camara.dart';
import 'presentation/screens/pantalla_galeria.dart';

/// Raíz de la app. Recibe las dependencias ya construidas (ver main.dart) para
/// poder sustituirlas en las pruebas.
class AppCamara extends StatelessWidget {
  const AppCamara({
    super.key,
    required this.ajustes,
    required this.galeria,
    required this.archivos,
    this.pestanaInicial = 0,
  });

  final EstadoAjustes ajustes;
  final EstadoGaleria galeria;
  final AlmacenArchivos archivos;
  final int pestanaInicial;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: ajustes),
        ChangeNotifierProvider.value(value: galeria),
        Provider.value(value: archivos),
      ],
      child: Consumer<EstadoAjustes>(
        builder: (context, a, _) => MaterialApp(
          title: 'Cámara P3',
          debugShowCheckedModeBanner: false,
          theme: crearTema(a.paleta, Brightness.light),
          darkTheme: crearTema(a.paleta, Brightness.dark),
          themeMode: a.modo,
          locale: const Locale('es', 'MX'),
          supportedLocales: const [Locale('es', 'MX'), Locale('es')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Inicio(pestanaInicial: pestanaInicial),
        ),
      ),
    );
  }
}

/// Navegación principal con barra inferior. Las pantallas se construyen solo
/// cuando están visibles, así la cámara se libera al cambiar de pestaña.
class Inicio extends StatefulWidget {
  const Inicio({super.key, this.pestanaInicial = 0});

  final int pestanaInicial;

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  late int _indice = widget.pestanaInicial;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: KeyedSubtree(
          key: ValueKey(_indice),
          child: switch (_indice) {
            0 => const PantallaCamara(),
            1 => const PantallaAudio(),
            2 => const PantallaGaleria(),
            _ => const PantallaAjustes(),
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: (i) => setState(() => _indice = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.photo_camera_outlined), selectedIcon: Icon(Icons.photo_camera), label: 'Cámara'),
          NavigationDestination(icon: Icon(Icons.mic_none), selectedIcon: Icon(Icons.mic), label: 'Audio'),
          NavigationDestination(icon: Icon(Icons.photo_library_outlined), selectedIcon: Icon(Icons.photo_library), label: 'Galería'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Ajustes'),
        ],
      ),
    );
  }
}
