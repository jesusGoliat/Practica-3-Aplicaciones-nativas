import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/inyeccion.dart';
import 'data/datasources/almacen_archivos.dart';
import 'data/datasources/base_datos_local.dart';
import 'data/datasources/preferencias.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX');

  // Todo se guarda en el directorio de documentos de la app: no hay red.
  final docs = await getApplicationDocumentsDirectory();
  final archivos = AlmacenArchivos(docs);
  await archivos.preparar();

  final deps = Dependencias(
    db: await BaseDatosLocal.abrir(p.join(docs.path, 'multimedia.db')),
    archivos: archivos,
    prefs: Preferencias(await SharedPreferences.getInstance()),
  );

  runApp(AppCamara(ajustes: deps.ajustes, galeria: deps.galeria, archivos: deps.archivos));
}
