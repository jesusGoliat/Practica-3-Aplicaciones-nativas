package mx.ipn.escom.p3.gestor.datos

import app.cash.sqldelight.coroutines.asFlow
import app.cash.sqldelight.coroutines.mapToList
import app.cash.sqldelight.db.SqlDriver
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import mx.ipn.escom.p3.gestor.bd.BaseGestor
import mx.ipn.escom.p3.gestor.dominio.EntradaArchivo
import mx.ipn.escom.p3.gestor.dominio.Orden

/** Favorito o reciente guardado en la base local. */
data class Marcador(val ruta: String, val nombre: String, val esCarpeta: Boolean, val fecha: Long)

/**
 * Persistencia con SQLDelight. Expone Flows que se actualizan solos cuando
 * cambia la tabla, así la interfaz siempre muestra el estado real.
 */
class RepositorioGestor(
    driver: SqlDriver,
    private val despachador: CoroutineDispatcher = Dispatchers.Default,
    private val reloj: () -> Long,
) {
    private val q = BaseGestor(driver).gestorQueries

    val favoritos: Flow<List<Marcador>> = q.favoritos().asFlow().mapToList(despachador).map { filas ->
        filas.map { Marcador(it.ruta, it.nombre, it.es_carpeta == 1L, it.agregado) }
    }

    val recientes: Flow<List<Marcador>> = q.recientes().asFlow().mapToList(despachador).map { filas ->
        filas.map { Marcador(it.ruta, it.nombre, false, it.abierto) }
    }

    suspend fun alternarFavorito(e: EntradaArchivo, esFavorito: Boolean) = withContext(despachador) {
        if (esFavorito) q.quitarFavorito(e.ruta)
        else q.agregarFavorito(e.ruta, e.nombre, if (e.esCarpeta) 1L else 0L, reloj())
    }

    suspend fun registrarReciente(e: EntradaArchivo) = withContext(despachador) {
        q.registrarReciente(e.ruta, e.nombre, reloj())
    }

    suspend fun limpiarRecientes() = withContext(despachador) { q.limpiarRecientes() }

    /** Mantiene favoritos y recientes al renombrar/mover; los quita al eliminar. */
    suspend fun rutaCambiada(anterior: String, nueva: String?, nombre: String) = withContext(despachador) {
        q.transaction {
            if (nueva == null) {
                q.quitarFavorito(anterior)
                q.quitarReciente(anterior)
            } else {
                q.moverFavorito(nueva = nueva, nombre = nombre, anterior = anterior)
                q.moverReciente(nueva = nueva, nombre = nombre, anterior = anterior)
            }
        }
    }

    // --- Preferencias de la sesión ---------------------------------------

    private fun leer(clave: String): String? = q.preferencia(clave).executeAsOneOrNull()
    private fun guardar(clave: String, valor: String) = q.guardarPreferencia(clave, valor)

    var ultimaCarpeta: String?
        get() = leer("ultimaCarpeta")
        set(v) { if (v != null) guardar("ultimaCarpeta", v) }

    var orden: Orden
        get() = leer("orden")?.let { runCatching { Orden.valueOf(it) }.getOrNull() } ?: Orden.NOMBRE
        set(v) = guardar("orden", v.name)

    var ascendente: Boolean
        get() = leer("ascendente")?.toBoolean() ?: true
        set(v) = guardar("ascendente", v.toString())

    var paleta: String
        get() = leer("paleta") ?: "GUINDA"
        set(v) = guardar("paleta", v)

    var sembrado: Boolean
        get() = leer("sembrado") == "true"
        set(v) = guardar("sembrado", v.toString())
}
