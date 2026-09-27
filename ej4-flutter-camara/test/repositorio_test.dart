import 'dart:io';

import 'package:flutter_camara/data/datasources/almacen_archivos.dart';
import 'package:flutter_camara/data/datasources/base_datos_local.dart';
import 'package:flutter_camara/data/repositories/repositorio_multimedia_impl.dart';
import 'package:flutter_camara/domain/entities/elemento_multimedia.dart';
import 'package:flutter_camara/domain/entities/filtro_foto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'sqlite_prueba.dart';

/// Pruebas de la capa de datos sin dispositivo: SQLite en memoria (FFI) y un
/// directorio temporal en lugar del almacenamiento de la app.
void main() {
  late Directory tmp;
  late RepositorioMultimediaImpl repo;

  setUpAll(iniciarSqlitePruebas);

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('p3_');
    final db = await BaseDatosLocal.abrir(inMemoryDatabasePath, fabrica: databaseFactoryFfiNoIsolate);
    repo = RepositorioMultimediaImpl(db, AlmacenArchivos(tmp));
  });

  tearDown(() async {
    // La base en memoria se comparte entre pruebas si no se borra.
    await databaseFactoryFfiNoIsolate.deleteDatabase(inMemoryDatabasePath);
    await tmp.delete(recursive: true);
  });

  Future<String> fotoDePrueba() async {
    final imagen = img.Image(width: 64, height: 32)..clear(img.ColorRgb8(200, 30, 60));
    final f = File(p.join(tmp.path, 'origen.png'));
    await f.writeAsBytes(img.encodePng(imagen));
    return f.path;
  }

  test('guardar foto crea archivo, miniatura y fila', () async {
    final foto = await repo.guardarFoto(await fotoDePrueba(), filtro: FiltroFoto.grises);

    expect(File(foto.ruta).existsSync(), isTrue);
    expect(File(foto.rutaMiniatura!).existsSync(), isTrue);
    final todas = await repo.obtenerTodos(tipo: TipoMultimedia.foto);
    expect(todas.single.filtro, 'grises');

    // El filtro de grises deja R = G = B.
    final guardada = img.decodeJpg(File(foto.ruta).readAsBytesSync())!;
    final px = guardada.getPixel(10, 10);
    expect((px.r - px.g).abs(), lessThan(4));
    expect((px.g - px.b).abs(), lessThan(4));
  });

  test('editar gira la foto 90 grados', () async {
    final foto = await repo.guardarFoto(await fotoDePrueba());
    await repo.editarFoto(foto, giroGrados: 90);
    final editada = img.decodeJpg(File(foto.ruta).readAsBytesSync())!;
    expect(editada.width, 32);
    expect(editada.height, 64);
  });

  test('álbumes, etiquetas y filtro por álbum', () async {
    await repo.crearAlbum('Escuela');
    expect(await repo.obtenerAlbumes(), containsAll(['General', 'Escuela']));

    final foto = await repo.guardarFoto(await fotoDePrueba());
    await repo.actualizar(foto.copyWith(album: 'Escuela', etiquetas: ['ipn', 'p3']));

    final escuela = await repo.obtenerTodos(album: 'Escuela');
    expect(escuela.single.etiquetas, ['ipn', 'p3']);
    expect(await repo.obtenerTodos(album: 'General'), isEmpty);
  });

  test('eliminar borra archivos y fila', () async {
    final foto = await repo.guardarFoto(await fotoDePrueba());
    await repo.eliminar(foto);
    expect(File(foto.ruta).existsSync(), isFalse);
    expect(await repo.obtenerTodos(), isEmpty);
  });

  test('importar rechaza tipos no soportados y archivos dañados', () async {
    final txt = File(p.join(tmp.path, 'nota.txt'))..writeAsStringSync('hola');
    expect(() => repo.importar(txt.path), throwsFormatException);

    final falsa = File(p.join(tmp.path, 'falsa.jpg'))..writeAsStringSync('no es imagen');
    expect(() => repo.importar(falsa.path), throwsA(anything));
  });

  test('audio importado se copia a la carpeta de la app', () async {
    final origen = File(p.join(tmp.path, 'externo', 'voz.m4a'))
      ..createSync(recursive: true)
      ..writeAsBytesSync([0, 1, 2]);
    final audio = await repo.guardarAudio(origen.path, duracionMs: 1500);
    expect(p.dirname(audio.ruta), endsWith('audios'));
    expect((await repo.obtenerTodos(tipo: TipoMultimedia.audio)).single.duracionMs, 1500);
  });
}
