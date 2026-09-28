package mx.ipn.escom.p3.gestor.datos

import mx.ipn.escom.p3.gestor.dominio.unir
import mx.ipn.escom.p3.gestor.plataforma.SistemaArchivos
import mx.ipn.escom.p3.gestor.recursos.Res
import org.jetbrains.compose.resources.ExperimentalResourceApi

/**
 * Crea archivos de ejemplo la primera vez que se abre la app, para que el
 * explorador no se vea vacío en el simulador/emulador. Todo es local.
 */
@OptIn(ExperimentalResourceApi::class)
suspend fun sembrarEjemplos(fs: SistemaArchivos, repo: RepositorioGestor, documentos: String) {
    if (repo.sembrado) return
    runCatching {
        val practica = unir(documentos, "Práctica 3")
        val fotos = unir(documentos, "Imágenes")
        listOf(practica, fotos, unir(documentos, "Notas")).forEach { if (!fs.existe(it)) fs.crearCarpeta(it) }

        fs.escribirBytes(
            unir(practica, "LEEME.md"),
            """
            # Gestor de archivos KMP
            
            Aplicación del **Ejercicio 5** de la Práctica 3 (ESCOM-IPN).
            
            - Lógica compartida en `commonMain`
            - Acceso a archivos con `expect`/`actual`
            - Persistencia con SQLDelight
            """.trimIndent().encodeToByteArray(),
        )
        fs.escribirBytes(
            unir(practica, "config.json"),
            """{ "tema": "guinda", "offline": true, "plataformas": ["android", "ios"] }""".encodeToByteArray(),
        )
        fs.escribirBytes(unir(documentos, "Notas/pendientes.txt"), "1. Capturas\n2. Informe\n3. Entrega\n".encodeToByteArray())
        fs.escribirBytes(unir(fotos, "escom.png"), Res.readBytes("files/muestra.png"))
        fs.escribirBytes(unir(documentos, "binario.dat"), ByteArray(64) { it.toByte() })
        repo.sembrado = true
    }
}
