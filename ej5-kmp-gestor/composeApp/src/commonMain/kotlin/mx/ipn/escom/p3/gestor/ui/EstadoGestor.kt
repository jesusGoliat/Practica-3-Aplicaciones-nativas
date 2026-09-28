package mx.ipn.escom.p3.gestor.ui

import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import mx.ipn.escom.p3.gestor.datos.Marcador
import mx.ipn.escom.p3.gestor.datos.RepositorioGestor
import mx.ipn.escom.p3.gestor.dominio.EntradaArchivo
import mx.ipn.escom.p3.gestor.dominio.Orden
import mx.ipn.escom.p3.gestor.dominio.Portapapeles
import mx.ipn.escom.p3.gestor.dominio.Raiz
import mx.ipn.escom.p3.gestor.dominio.filtrar
import mx.ipn.escom.p3.gestor.dominio.nombreLibre
import mx.ipn.escom.p3.gestor.dominio.ordenar
import mx.ipn.escom.p3.gestor.dominio.padreDe
import mx.ipn.escom.p3.gestor.dominio.unir
import mx.ipn.escom.p3.gestor.dominio.validarNombre
import mx.ipn.escom.p3.gestor.plataforma.SistemaArchivos

/** Todo lo que la pantalla del explorador necesita para dibujarse. */
data class EstadoExplorador(
    val raiz: Raiz,
    val rutaActual: String,
    val entradas: List<EntradaArchivo> = emptyList(),
    val consulta: String = "",
    val orden: Orden = Orden.NOMBRE,
    val ascendente: Boolean = true,
    val cargando: Boolean = false,
    val portapapeles: Portapapeles? = null,
    val mensaje: String? = null,
) {
    val enRaiz: Boolean get() = rutaActual.trimEnd('/') == raiz.ruta.trimEnd('/')

    /** Ruta relativa a la raíz, para mostrar "Documentos / Fotos / 2026". */
    val migas: List<Pair<String, String>>
        get() {
            val relativa = rutaActual.removePrefix(raiz.ruta).trim('/')
            val partes = if (relativa.isEmpty()) emptyList() else relativa.split('/')
            var acumulada = raiz.ruta.trimEnd('/')
            return listOf(raiz.nombre to raiz.ruta) + partes.map { p ->
                acumulada = "$acumulada/$p"
                p to acumulada
            }
        }
}

/**
 * Lógica del gestor (equivalente a un ViewModel). Usa corrutinas para no
 * bloquear la interfaz y expone el estado como StateFlow.
 */
class EstadoGestor(
    private val fs: SistemaArchivos,
    private val repo: RepositorioGestor,
    private val alcance: CoroutineScope,
    private val despachador: CoroutineDispatcher = Dispatchers.Default,
) {
    val raices: List<Raiz> = fs.raices()

    private var todas: List<EntradaArchivo> = emptyList()

    private val _estado = MutableStateFlow(
        EstadoExplorador(
            raiz = raices.first(),
            rutaActual = repo.ultimaCarpeta?.takeIf { fs.existe(it) && raices.any { r -> it.startsWith(r.ruta) } }
                ?: raices.first().ruta,
            orden = repo.orden,
            ascendente = repo.ascendente,
        ).let { e -> e.copy(raiz = raices.firstOrNull { e.rutaActual.startsWith(it.ruta) } ?: raices.first()) },
    )
    val estado: StateFlow<EstadoExplorador> = _estado.asStateFlow()

    val favoritos: StateFlow<List<Marcador>> = repo.favoritos.stateIn(alcance, SharingStarted.Eagerly, emptyList())
    val recientes: StateFlow<List<Marcador>> = repo.recientes.stateIn(alcance, SharingStarted.Eagerly, emptyList())
    val rutasFavoritas: StateFlow<Set<String>> =
        repo.favoritos.map { l -> l.map { it.ruta }.toSet() }.stateIn(alcance, SharingStarted.Eagerly, emptySet())

    private val _paleta = MutableStateFlow(Paleta.porNombre(repo.paleta))
    val paleta: StateFlow<Paleta> = _paleta.asStateFlow()

    init {
        refrescar()
    }

    // --- Navegación --------------------------------------------------------

    fun abrirCarpeta(ruta: String) {
        val raiz = raices.firstOrNull { ruta.startsWith(it.ruta) } ?: return // fuera del sandbox: se ignora
        repo.ultimaCarpeta = ruta
        _estado.update { it.copy(raiz = raiz, rutaActual = ruta, consulta = "") }
        refrescar()
    }

    fun cambiarRaiz(raiz: Raiz) = abrirCarpeta(raiz.ruta)

    fun subir() {
        val e = _estado.value
        if (!e.enRaiz) abrirCarpeta(padreDe(e.rutaActual))
    }

    fun refrescar() {
        alcance.launch {
            _estado.update { it.copy(cargando = true) }
            val ruta = _estado.value.rutaActual
            val resultado = runCatching { withContext(despachador) { fs.listar(ruta) } }
            resultado.onSuccess { todas = it }
                .onFailure { todas = emptyList(); avisar("No se pudo leer la carpeta: ${it.message}") }
            aplicarVista()
            _estado.update { it.copy(cargando = false) }
        }
    }

    fun buscar(consulta: String) {
        _estado.update { it.copy(consulta = consulta) }
        aplicarVista()
    }

    fun cambiarOrden(orden: Orden) {
        val e = _estado.value
        // Elegir el mismo criterio invierte la dirección.
        val asc = if (e.orden == orden) !e.ascendente else true
        repo.orden = orden
        repo.ascendente = asc
        _estado.update { it.copy(orden = orden, ascendente = asc) }
        aplicarVista()
    }

    private fun aplicarVista() {
        _estado.update { it.copy(entradas = ordenar(filtrar(todas, it.consulta), it.orden, it.ascendente)) }
    }

    // --- Operaciones sobre archivos -------------------------------------

    fun crearCarpeta(nombre: String) = operar("Carpeta creada") {
        validarNombre(nombre)?.let { error(it) }
        val destino = unir(_estado.value.rutaActual, nombre.trim())
        if (fs.existe(destino)) error("Ya existe un elemento con ese nombre.")
        fs.crearCarpeta(destino)
    }

    fun renombrar(e: EntradaArchivo, nuevo: String) = operar("Renombrado") {
        validarNombre(nuevo)?.let { error(it) }
        val destino = unir(padreDe(e.ruta), nuevo.trim())
        if (destino == e.ruta) return@operar
        if (fs.existe(destino)) error("Ya existe un elemento con ese nombre.")
        fs.renombrar(e.ruta, destino)
        repo.rutaCambiada(e.ruta, destino, nuevo.trim())
    }

    fun eliminar(e: EntradaArchivo) = operar("Eliminado") {
        fs.eliminar(e.ruta)
        repo.rutaCambiada(e.ruta, null, e.nombre)
    }

    fun copiar(e: EntradaArchivo, cortar: Boolean) {
        _estado.update { it.copy(portapapeles = Portapapeles(e, cortar)) }
        avisar(if (cortar) "Listo para mover: ve a otra carpeta y pulsa Pegar" else "Copiado: ve a otra carpeta y pulsa Pegar")
    }

    fun cancelarPegar() = _estado.update { it.copy(portapapeles = null) }

    fun pegar() {
        val pp = _estado.value.portapapeles ?: return
        val carpeta = _estado.value.rutaActual
        operar(if (pp.cortar) "Movido" else "Copiado") {
            if (pp.entrada.esCarpeta && (carpeta == pp.entrada.ruta || carpeta.startsWith(pp.entrada.ruta + "/"))) {
                error("No se puede pegar una carpeta dentro de sí misma.")
            }
            val nombre = nombreLibre(pp.entrada.nombre) { fs.existe(unir(carpeta, it)) }
            val destino = unir(carpeta, nombre)
            if (pp.cortar) {
                fs.mover(pp.entrada.ruta, destino)
                repo.rutaCambiada(pp.entrada.ruta, destino, nombre)
            } else {
                fs.copiar(pp.entrada.ruta, destino)
            }
            _estado.update { it.copy(portapapeles = null) }
        }
    }

    fun alternarFavorito(e: EntradaArchivo) {
        alcance.launch { repo.alternarFavorito(e, e.ruta in rutasFavoritas.value) }
    }

    /** Registra el archivo en "Recientes" al abrirlo. */
    fun abrioArchivo(e: EntradaArchivo) {
        alcance.launch { repo.registrarReciente(e) }
    }

    fun limpiarRecientes() {
        alcance.launch { repo.limpiarRecientes() }
    }

    fun infoDe(ruta: String): EntradaArchivo? = fs.info(ruta)

    /** Lee un archivo como texto; los binarios o dañados producen un error claro. */
    suspend fun leerTexto(e: EntradaArchivo): Result<String> = withContext(despachador) {
        runCatching {
            if (e.tamano > 2_000_000) error("El archivo es demasiado grande para la vista previa (${e.tamano} bytes).")
            val bytes = fs.leerBytes(e.ruta)
            if (bytes.any { it == 0.toByte() }) error("El archivo no parece ser de texto.")
            bytes.decodeToString()
        }
    }

    suspend fun leerBytes(e: EntradaArchivo): Result<ByteArray> = withContext(despachador) {
        runCatching { fs.leerBytes(e.ruta) }
    }

    fun importados(rutas: List<String>) {
        if (rutas.isNotEmpty()) avisar("${rutas.size} archivo(s) importado(s)")
        refrescar()
    }

    fun cambiarPaleta(p: Paleta) {
        repo.paleta = p.name
        _paleta.value = p
    }

    fun mensajeMostrado() = _estado.update { it.copy(mensaje = null) }

    private fun avisar(texto: String) = _estado.update { it.copy(mensaje = texto) }

    private fun operar(exito: String, bloque: suspend () -> Unit) {
        alcance.launch {
            runCatching { withContext(despachador) { bloque() } }
                .onSuccess { avisar(exito) }
                .onFailure { avisar(it.message ?: "Ocurrió un error") }
            refrescar()
        }
    }
}
