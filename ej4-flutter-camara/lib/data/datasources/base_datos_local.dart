import 'package:sqflite/sqflite.dart';

import '../../domain/entities/elemento_multimedia.dart';

/// Acceso a SQLite (sqflite). Guarda solo metadatos; los archivos viven en
/// el directorio de documentos de la app (ver [AlmacenArchivos]).
class BaseDatosLocal {
  BaseDatosLocal(this._db);

  final Database _db;

  static const _version = 1;

  /// Abre (o crea) la base. [ruta] puede ser `inMemoryDatabasePath` en pruebas.
  static Future<BaseDatosLocal> abrir(String ruta, {DatabaseFactory? fabrica}) async {
    final f = fabrica ?? databaseFactory;
    final db = await f.openDatabase(
      ruta,
      options: OpenDatabaseOptions(version: _version, onCreate: _crear),
    );
    return BaseDatosLocal(db);
  }

  static Future<void> _crear(Database db, int version) async {
    await db.execute('''
      CREATE TABLE multimedia (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tipo TEXT NOT NULL,
        ruta TEXT NOT NULL,
        miniatura TEXT,
        fecha INTEGER NOT NULL,
        album TEXT NOT NULL,
        etiquetas TEXT NOT NULL DEFAULT '',
        filtro TEXT,
        duracion_ms INTEGER
      )''');
    await db.execute('CREATE TABLE albumes (nombre TEXT PRIMARY KEY)');
    await db.insert('albumes', {'nombre': ElementoMultimedia.albumGeneral});
  }

  Future<List<Map<String, Object?>>> consultar({String? tipo, String? album}) {
    final condiciones = <String>[];
    final args = <Object?>[];
    if (tipo != null) {
      condiciones.add('tipo = ?');
      args.add(tipo);
    }
    if (album != null) {
      condiciones.add('album = ?');
      args.add(album);
    }
    return _db.query(
      'multimedia',
      where: condiciones.isEmpty ? null : condiciones.join(' AND '),
      whereArgs: args,
      orderBy: 'fecha DESC',
    );
  }

  Future<int> insertar(Map<String, Object?> fila) => _db.insert('multimedia', fila);

  Future<void> actualizar(int id, Map<String, Object?> fila) =>
      _db.update('multimedia', fila, where: 'id = ?', whereArgs: [id]);

  Future<void> eliminar(int id) => _db.delete('multimedia', where: 'id = ?', whereArgs: [id]);

  Future<List<String>> albumes() async {
    final filas = await _db.query('albumes', orderBy: 'nombre');
    return filas.map((f) => f['nombre'] as String).toList();
  }

  Future<void> crearAlbum(String nombre) =>
      _db.insert('albumes', {'nombre': nombre}, conflictAlgorithm: ConflictAlgorithm.ignore);
}
