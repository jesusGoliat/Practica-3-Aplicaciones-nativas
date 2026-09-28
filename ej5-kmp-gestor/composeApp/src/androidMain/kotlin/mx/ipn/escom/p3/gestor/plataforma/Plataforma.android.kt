package mx.ipn.escom.p3.gestor.plataforma

import android.content.Context
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import android.provider.OpenableColumns
import android.webkit.MimeTypeMap
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asImageBitmap
import androidx.core.content.FileProvider
import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.driver.android.AndroidSqliteDriver
import mx.ipn.escom.p3.gestor.bd.BaseGestor
import mx.ipn.escom.p3.gestor.dominio.EntradaArchivo
import mx.ipn.escom.p3.gestor.dominio.Raiz
import mx.ipn.escom.p3.gestor.dominio.nombreLibre
import java.io.File
import java.io.IOException
import java.text.DateFormat
import java.util.Date
import java.util.Locale

/** Contexto de la app, asignado en GestorApplication.onCreate. */
object ContextoAndroid {
    lateinit var app: Context
}

// Android: almacenamiento interno de la app (filesDir y cacheDir), sin
// permisos adicionales. java.io.File hace el trabajo.
actual class SistemaArchivos actual constructor() {
    private val ctx get() = ContextoAndroid.app

    actual fun raices(): List<Raiz> = listOf(
        Raiz("Documentos", File(ctx.filesDir, "Documentos").apply { mkdirs() }.absolutePath),
        Raiz("Temporales", ctx.cacheDir.absolutePath),
    )

    actual fun listar(ruta: String): List<EntradaArchivo> {
        val dir = File(ruta)
        if (!dir.isDirectory) throw IOException("No es una carpeta")
        return dir.listFiles()?.map { it.aEntrada() } ?: throw IOException("Sin acceso a la carpeta")
    }

    actual fun info(ruta: String): EntradaArchivo? = File(ruta).takeIf { it.exists() }?.aEntrada()

    actual fun existe(ruta: String): Boolean = File(ruta).exists()

    actual fun crearCarpeta(ruta: String) {
        if (!File(ruta).mkdirs()) throw IOException("No se pudo crear la carpeta")
    }

    actual fun renombrar(origen: String, destino: String) {
        if (!File(origen).renameTo(File(destino))) throw IOException("No se pudo renombrar")
    }

    actual fun copiar(origen: String, destino: String) {
        File(origen).copyRecursively(File(destino), overwrite = false)
    }

    actual fun mover(origen: String, destino: String) {
        if (!File(origen).renameTo(File(destino))) {
            copiar(origen, destino)
            eliminar(origen)
        }
    }

    actual fun eliminar(ruta: String) {
        if (!File(ruta).deleteRecursively()) throw IOException("No se pudo eliminar")
    }

    actual fun leerBytes(ruta: String): ByteArray = File(ruta).readBytes()

    actual fun escribirBytes(ruta: String, datos: ByteArray) {
        File(ruta).apply { parentFile?.mkdirs() }.writeBytes(datos)
    }

    private fun File.aEntrada() = EntradaArchivo(
        ruta = absolutePath,
        nombre = name,
        esCarpeta = isDirectory,
        tamano = if (isDirectory) 0 else length(),
        modificado = lastModified(),
    )
}

actual fun crearDriver(): SqlDriver = AndroidSqliteDriver(BaseGestor.Schema, ContextoAndroid.app, "gestor.db")

actual fun formatearFecha(millis: Long): String =
    DateFormat.getDateTimeInstance(DateFormat.MEDIUM, DateFormat.SHORT, Locale("es", "MX")).format(Date(millis))

actual fun decodificarImagen(bytes: ByteArray): ImageBitmap? =
    BitmapFactory.decodeByteArray(bytes, 0, bytes.size)?.asImageBitmap()

actual fun compartirArchivo(ruta: String) {
    val ctx = ContextoAndroid.app
    val archivo = File(ruta)
    val uri = FileProvider.getUriForFile(ctx, "${ctx.packageName}.archivos", archivo)
    val tipo = MimeTypeMap.getSingleton().getMimeTypeFromExtension(archivo.extension.lowercase()) ?: "*/*"
    val enviar = Intent(Intent.ACTION_SEND).apply {
        type = tipo
        putExtra(Intent.EXTRA_STREAM, uri)
        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    }
    ctx.startActivity(Intent.createChooser(enviar, "Compartir ${archivo.name}").addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
}

@Composable
actual fun rememberImportador(carpetaDestino: String, alTerminar: (List<String>) -> Unit): () -> Unit {
    val lanzador = rememberLauncherForActivityResult(ActivityResultContracts.OpenMultipleDocuments()) { uris ->
        alTerminar(uris.mapNotNull { copiarDesde(it, carpetaDestino) })
    }
    return { lanzador.launch(arrayOf("*/*")) }
}

/** Copia el contenido de un Uri del selector al almacenamiento de la app. */
private fun copiarDesde(uri: Uri, carpeta: String): String? = runCatching {
    val cr = ContextoAndroid.app.contentResolver
    val nombre = cr.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)?.use { c ->
        if (c.moveToFirst()) c.getString(0) else null
    } ?: "importado"
    val libre = nombreLibre(nombre) { File(carpeta, it).exists() }
    val destino = File(carpeta, libre)
    cr.openInputStream(uri)?.use { entrada -> destino.outputStream().use { entrada.copyTo(it) } }
        ?: throw IOException("Sin acceso")
    destino.absolutePath
}.getOrNull()

@Composable
actual fun ManejarAtras(activo: Boolean, accion: () -> Unit) = BackHandler(enabled = activo, onBack = accion)

actual fun ahoraMillis(): Long = System.currentTimeMillis()

actual val nombrePlataforma: String = "Android ${android.os.Build.VERSION.RELEASE}"
