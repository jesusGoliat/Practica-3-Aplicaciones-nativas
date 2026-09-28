package mx.ipn.escom.p3.gestor.dominio

/** Un archivo o carpeta tal como lo muestra el explorador. */
data class EntradaArchivo(
    val ruta: String,
    val nombre: String,
    val esCarpeta: Boolean,
    val tamano: Long,
    /** Fecha de modificación en milisegundos desde 1970. */
    val modificado: Long,
) {
    val extension: String get() = nombre.substringAfterLast('.', "").lowercase()
    val tipo: TipoArchivo get() = if (esCarpeta) TipoArchivo.CARPETA else TipoArchivo.deExtension(extension)
}

/** Directorio raíz accesible para la app dentro de su sandbox. */
data class Raiz(val nombre: String, val ruta: String)

enum class TipoArchivo {
    CARPETA, TEXTO, IMAGEN, AUDIO, VIDEO, PDF, COMPRIMIDO, OTRO;

    companion object {
        private val texto = setOf("txt", "md", "json", "xml", "csv", "log", "kt", "swift", "dart", "yaml", "yml", "html", "js")
        private val imagen = setOf("jpg", "jpeg", "png", "gif", "webp", "bmp", "heic")
        private val audio = setOf("mp3", "m4a", "aac", "wav", "ogg", "caf")
        private val video = setOf("mp4", "mov", "m4v", "3gp", "mkv")
        private val comprimido = setOf("zip", "rar", "7z", "tar", "gz")

        fun deExtension(ext: String): TipoArchivo = when (ext.lowercase()) {
            in texto -> TEXTO
            in imagen -> IMAGEN
            in audio -> AUDIO
            in video -> VIDEO
            "pdf" -> PDF
            in comprimido -> COMPRIMIDO
            else -> OTRO
        }
    }
}

enum class Orden(val etiqueta: String) { NOMBRE("Nombre"), FECHA("Fecha"), TAMANO("Tamaño") }

/** Archivo marcado para copiar o mover con "Pegar aquí". */
data class Portapapeles(val entrada: EntradaArchivo, val cortar: Boolean)

/**
 * Ordena con las carpetas siempre primero y luego por el criterio elegido.
 * Es lógica pura, así que se prueba en commonTest.
 */
fun ordenar(lista: List<EntradaArchivo>, orden: Orden, ascendente: Boolean): List<EntradaArchivo> {
    val criterio: Comparator<EntradaArchivo> = when (orden) {
        Orden.NOMBRE -> compareBy { it.nombre.lowercase() }
        Orden.FECHA -> compareBy { it.modificado }
        Orden.TAMANO -> compareBy { it.tamano }
    }
    val dirigido = if (ascendente) criterio else criterio.reversed()
    return lista.sortedWith(compareByDescending<EntradaArchivo> { it.esCarpeta }.then(dirigido))
}

fun filtrar(lista: List<EntradaArchivo>, consulta: String): List<EntradaArchivo> =
    if (consulta.isBlank()) lista else lista.filter { it.nombre.contains(consulta.trim(), ignoreCase = true) }

fun formatearTamano(bytes: Long): String = when {
    bytes < 1024 -> "$bytes B"
    bytes < 1024 * 1024 -> "${redondear(bytes / 1024.0)} KB"
    bytes < 1024L * 1024 * 1024 -> "${redondear(bytes / (1024.0 * 1024))} MB"
    else -> "${redondear(bytes / (1024.0 * 1024 * 1024))} GB"
}

private fun redondear(v: Double): String {
    val entero = (v * 10).toLong()
    return "${entero / 10}.${entero % 10}"
}

/** Valida un nombre de archivo o carpeta. Devuelve el error o null si es válido. */
fun validarNombre(nombre: String): String? = when {
    nombre.isBlank() -> "El nombre no puede estar vacío."
    nombre.contains('/') || nombre.contains(':') -> "El nombre no puede contener / ni :"
    nombre == "." || nombre == ".." -> "Nombre reservado."
    nombre.length > 255 -> "El nombre es demasiado largo."
    else -> null
}

/** Une rutas con "/" (Android e iOS usan rutas estilo Unix). */
fun unir(padre: String, nombre: String): String = padre.trimEnd('/') + "/" + nombre

fun padreDe(ruta: String): String = ruta.trimEnd('/').substringBeforeLast('/', "/")

/** Si "nombre" ya existe en la carpeta, genera "nombre (1)", "nombre (2)", etc. */
fun nombreLibre(nombre: String, existe: (String) -> Boolean): String {
    if (!existe(nombre)) return nombre
    val base = nombre.substringBeforeLast('.', nombre)
    val ext = nombre.substringAfterLast('.', "").let { if (it.isEmpty() || it == nombre) "" else ".$it" }
    var i = 1
    while (existe("$base ($i)$ext")) i++
    return "$base ($i)$ext"
}
