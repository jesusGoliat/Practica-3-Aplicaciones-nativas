package mx.ipn.escom.p3.gestor.plataforma

import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.ImageBitmap
import app.cash.sqldelight.db.SqlDriver
import mx.ipn.escom.p3.gestor.dominio.EntradaArchivo
import mx.ipn.escom.p3.gestor.dominio.Raiz

// Declaraciones expect: lo que cambia entre Android e iOS. Cada una tiene su
// implementación `actual` en androidMain (java.io, Intent, BitmapFactory) y en
// iosMain (NSFileManager, UIActivityViewController, Skia).

/** Acceso al sistema de archivos dentro del sandbox de la app. */
expect class SistemaArchivos() {
    /** Directorios accesibles: Documentos y Temporales. */
    fun raices(): List<Raiz>
    fun listar(ruta: String): List<EntradaArchivo>
    fun info(ruta: String): EntradaArchivo?
    fun existe(ruta: String): Boolean
    fun crearCarpeta(ruta: String)
    fun renombrar(origen: String, destino: String)
    fun copiar(origen: String, destino: String)
    fun mover(origen: String, destino: String)
    fun eliminar(ruta: String)
    fun leerBytes(ruta: String): ByteArray
    fun escribirBytes(ruta: String, datos: ByteArray)
}

/** Driver de SQLite para SQLDelight (Android: SQLiteOpenHelper, iOS: SQLite nativo). */
expect fun crearDriver(): SqlDriver

/** Formato de fecha con las convenciones del sistema (es-MX). */
expect fun formatearFecha(millis: Long): String

/** Decodifica una imagen (PNG, JPEG…) para mostrarla en Compose. */
expect fun decodificarImagen(bytes: ByteArray): ImageBitmap?

/** Abre la hoja de compartir del sistema para exportar un archivo. */
expect fun compartirArchivo(ruta: String)

/**
 * Selector de documentos del sistema (Storage Access Framework en Android,
 * UIDocumentPickerViewController en iOS). Los archivos elegidos se copian a
 * [carpetaDestino] y se devuelven sus nuevas rutas. El permiso de lectura lo
 * concede el propio selector: es el mecanismo de permisos de cada plataforma.
 */
@Composable
expect fun rememberImportador(carpetaDestino: String, alTerminar: (List<String>) -> Unit): () -> Unit

/** Nombre de la plataforma para la pantalla "Acerca de". */
expect val nombrePlataforma: String

/** Botón/gesto "atrás" del sistema (Android). En iOS no hay botón físico. */
@Composable
expect fun ManejarAtras(activo: Boolean, accion: () -> Unit)

/** Hora actual en milisegundos desde 1970. */
expect fun ahoraMillis(): Long
