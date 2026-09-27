import 'dart:ffi';
import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqlite3/open.dart';

/// Inicializa SQLite por FFI para las pruebas. En varias distribuciones de
/// Linux solo existe `libsqlite3.so.0` (sin el paquete -dev), así que se
/// abre esa biblioteca explícitamente.
void iniciarSqlitePruebas() {
  if (Platform.isLinux) {
    open.overrideFor(OperatingSystem.linux, () {
      try {
        return DynamicLibrary.open('libsqlite3.so');
      } catch (_) {
        return DynamicLibrary.open('libsqlite3.so.0');
      }
    });
  }
  sqfliteFfiInit();
}
