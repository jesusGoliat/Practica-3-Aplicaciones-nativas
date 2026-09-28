@file:OptIn(ExperimentalForeignApi::class, BetaInteropApi::class)

package mx.ipn.escom.p3.gestor.plataforma

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.toComposeImageBitmap
import app.cash.sqldelight.db.SqlDriver
import app.cash.sqldelight.driver.native.NativeSqliteDriver
import kotlinx.cinterop.BetaInteropApi
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.addressOf
import kotlinx.cinterop.usePinned
import mx.ipn.escom.p3.gestor.bd.BaseGestor
import mx.ipn.escom.p3.gestor.dominio.EntradaArchivo
import mx.ipn.escom.p3.gestor.dominio.Raiz
import mx.ipn.escom.p3.gestor.dominio.nombreLibre
import mx.ipn.escom.p3.gestor.dominio.unir
import platform.Foundation.NSData
import platform.Foundation.NSDate
import platform.Foundation.NSDateFormatter
import platform.Foundation.NSDateFormatterMediumStyle
import platform.Foundation.NSDateFormatterShortStyle
import platform.Foundation.NSDocumentDirectory
import platform.Foundation.NSFileManager
import platform.Foundation.NSFileModificationDate
import platform.Foundation.NSFileSize
import platform.Foundation.NSFileType
import platform.Foundation.NSFileTypeDirectory
import platform.Foundation.NSLocale
import platform.Foundation.NSNumber
import platform.Foundation.NSSearchPathForDirectoriesInDomains
import platform.Foundation.NSTemporaryDirectory
import platform.Foundation.NSURL
import platform.Foundation.NSUserDomainMask
import platform.Foundation.dataWithBytes
import platform.Foundation.dataWithContentsOfFile
import platform.Foundation.dateWithTimeIntervalSince1970
import platform.Foundation.timeIntervalSince1970
import platform.Foundation.writeToFile
import platform.UIKit.UIActivityViewController
import platform.UIKit.UIApplication
import platform.UIKit.UIDevice
import platform.UIKit.UIDocumentPickerDelegateProtocol
import platform.UIKit.UIDocumentPickerViewController
import platform.UIKit.UIViewController
import platform.UIKit.popoverPresentationController
import platform.UniformTypeIdentifiers.UTTypeItem
import platform.darwin.NSObject
import platform.posix.memcpy

// iOS: todo ocurre dentro del contenedor (sandbox) de la app. NSFileManager
// hace el trabajo; no se intenta acceder a rutas fuera de Documents y tmp.
actual class SistemaArchivos actual constructor() {
    private val fm = NSFileManager.defaultManager

    actual fun raices(): List<Raiz> = listOf(
        Raiz("Documentos", NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).first() as String),
        Raiz("Temporales", NSTemporaryDirectory().trimEnd('/')),
    )

    actual fun listar(ruta: String): List<EntradaArchivo> {
        val nombres = fm.contentsOfDirectoryAtPath(ruta, null) ?: throw IllegalStateException("Sin acceso a la carpeta")
        return nombres.mapNotNull { info(unir(ruta, it as String)) }
    }

    actual fun info(ruta: String): EntradaArchivo? {
        val attrs = fm.attributesOfItemAtPath(ruta, null) ?: return null
        val esCarpeta = attrs[NSFileType] == NSFileTypeDirectory
        return EntradaArchivo(
            ruta = ruta,
            nombre = ruta.substringAfterLast('/'),
            esCarpeta = esCarpeta,
            tamano = if (esCarpeta) 0 else (attrs[NSFileSize] as? NSNumber)?.longLongValue ?: 0,
            modificado = ((attrs[NSFileModificationDate] as? NSDate)?.timeIntervalSince1970 ?: 0.0).times(1000).toLong(),
        )
    }

    actual fun existe(ruta: String): Boolean = fm.fileExistsAtPath(ruta)

    actual fun crearCarpeta(ruta: String) {
        check(fm.createDirectoryAtPath(ruta, withIntermediateDirectories = true, attributes = null, error = null)) {
            "No se pudo crear la carpeta"
        }
    }

    actual fun renombrar(origen: String, destino: String) = mover(origen, destino)

    actual fun copiar(origen: String, destino: String) {
        check(fm.copyItemAtPath(origen, toPath = destino, error = null)) { "No se pudo copiar" }
    }

    actual fun mover(origen: String, destino: String) {
        check(fm.moveItemAtPath(origen, toPath = destino, error = null)) { "No se pudo mover" }
    }

    actual fun eliminar(ruta: String) {
        check(fm.removeItemAtPath(ruta, error = null)) { "No se pudo eliminar" }
    }

    actual fun leerBytes(ruta: String): ByteArray {
        val datos = NSData.dataWithContentsOfFile(ruta) ?: throw IllegalStateException("No se pudo leer el archivo")
        val tam = datos.length.toInt()
        val bytes = ByteArray(tam)
        if (tam > 0) bytes.usePinned { memcpy(it.addressOf(0), datos.bytes, datos.length) }
        return bytes
    }

    actual fun escribirBytes(ruta: String, datos: ByteArray) {
        val padre = ruta.substringBeforeLast('/')
        if (!existe(padre)) crearCarpeta(padre)
        val nsdata = if (datos.isEmpty()) NSData() else datos.usePinned {
            NSData.dataWithBytes(it.addressOf(0), datos.size.toULong())
        }
        check(nsdata.writeToFile(ruta, atomically = true)) { "No se pudo escribir el archivo" }
    }
}

actual fun crearDriver(): SqlDriver = NativeSqliteDriver(BaseGestor.Schema, "gestor.db")

actual fun formatearFecha(millis: Long): String {
    val formato = NSDateFormatter().apply {
        locale = NSLocale(localeIdentifier = "es_MX")
        dateStyle = NSDateFormatterMediumStyle
        timeStyle = NSDateFormatterShortStyle
    }
    return formato.stringFromDate(NSDate.dateWithTimeIntervalSince1970(millis / 1000.0))
}

actual fun decodificarImagen(bytes: ByteArray): ImageBitmap? =
    runCatching { org.jetbrains.skia.Image.makeFromEncoded(bytes).toComposeImageBitmap() }.getOrNull()

/** Controlador visible en primer plano, para presentar hojas del sistema. */
private fun controladorSuperior(): UIViewController? {
    var vc = UIApplication.sharedApplication.keyWindow?.rootViewController
    while (vc?.presentedViewController != null) vc = vc.presentedViewController
    return vc
}

actual fun compartirArchivo(ruta: String) {
    val vc = controladorSuperior() ?: return
    val hoja = UIActivityViewController(activityItems = listOf(NSURL.fileURLWithPath(ruta)), applicationActivities = null)
    // En iPad la hoja se muestra como popover y necesita un origen.
    hoja.popoverPresentationController?.sourceView = vc.view
    vc.presentViewController(hoja, animated = true, completion = null)
}

/** Delegado del selector: copia lo elegido a la carpeta actual. */
internal class DelegadoImportar(
    private val carpeta: () -> String,
    private val alTerminar: (List<String>) -> Unit,
) : NSObject(), UIDocumentPickerDelegateProtocol {
    override fun documentPicker(controller: UIDocumentPickerViewController, didPickDocumentsAtURLs: List<*>) {
        val fm = NSFileManager.defaultManager
        val destino = carpeta()
        val copiados = didPickDocumentsAtURLs.mapNotNull { elemento ->
            val url = elemento as? NSURL ?: return@mapNotNull null
            // Acceso con alcance de seguridad (security-scoped) mientras se copia.
            val acceso = url.startAccessingSecurityScopedResource()
            try {
                val nombre = url.lastPathComponent ?: "importado"
                val libre = nombreLibre(nombre) { fm.fileExistsAtPath(unir(destino, it)) }
                val ruta = unir(destino, libre)
                if (fm.copyItemAtURL(url, toURL = NSURL.fileURLWithPath(ruta), error = null)) ruta else null
            } finally {
                if (acceso) url.stopAccessingSecurityScopedResource()
            }
        }
        alTerminar(copiados)
    }

    override fun documentPickerWasCancelled(controller: UIDocumentPickerViewController) = Unit
}

@Composable
actual fun rememberImportador(carpetaDestino: String, alTerminar: (List<String>) -> Unit): () -> Unit {
    val carpetaActual = rememberActualizado(carpetaDestino)
    // El delegado se guarda con remember porque UIKit lo referencia de forma débil.
    val delegado = remember { DelegadoImportar({ carpetaActual.valor }, alTerminar) }
    return {
        val selector = UIDocumentPickerViewController(forOpeningContentTypes = listOf(UTTypeItem), asCopy = true)
        selector.allowsMultipleSelection = true
        selector.delegate = delegado
        controladorSuperior()?.presentViewController(selector, animated = true, completion = null)
    }
}

/** Contenedor mutable para leer siempre el valor más reciente desde UIKit. */
private class Actualizado<T>(var valor: T)

@Composable
private fun <T> rememberActualizado(valor: T): Actualizado<T> = remember { Actualizado(valor) }.also { it.valor = valor }

// En iOS no hay botón "atrás" del sistema: se usa el botón de la barra superior.
@Composable
actual fun ManejarAtras(activo: Boolean, accion: () -> Unit) = Unit

actual fun ahoraMillis(): Long = (NSDate().timeIntervalSince1970 * 1000).toLong()

actual val nombrePlataforma: String =
    "${UIDevice.currentDevice.systemName} ${UIDevice.currentDevice.systemVersion}"
