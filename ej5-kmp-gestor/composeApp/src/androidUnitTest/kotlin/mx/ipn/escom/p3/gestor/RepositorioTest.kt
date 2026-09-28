package mx.ipn.escom.p3.gestor

import app.cash.sqldelight.driver.jdbc.sqlite.JdbcSqliteDriver
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import mx.ipn.escom.p3.gestor.bd.BaseGestor
import mx.ipn.escom.p3.gestor.datos.RepositorioGestor
import mx.ipn.escom.p3.gestor.dominio.EntradaArchivo
import mx.ipn.escom.p3.gestor.dominio.Orden
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

/** Persistencia con SQLDelight usando SQLite en memoria (JVM). */
class RepositorioTest {
    private var reloj = 1000L
    private val repo = RepositorioGestor(
        JdbcSqliteDriver(JdbcSqliteDriver.IN_MEMORY).also { BaseGestor.Schema.create(it) },
        Dispatchers.Unconfined,
        reloj = { reloj++ },
    )
    private val nota = EntradaArchivo("/d/nota.txt", "nota.txt", false, 5, 0)

    @Test
    fun favoritosSeAgreganYQuitan() = runTest {
        repo.alternarFavorito(nota, esFavorito = false)
        assertEquals(listOf("nota.txt"), repo.favoritos.first().map { it.nombre })
        repo.alternarFavorito(nota, esFavorito = true)
        assertTrue(repo.favoritos.first().isEmpty())
    }

    @Test
    fun recientesOrdenadosDelMasNuevo() = runTest {
        repo.registrarReciente(nota)
        repo.registrarReciente(nota.copy(ruta = "/d/b.md", nombre = "b.md"))
        assertEquals(listOf("b.md", "nota.txt"), repo.recientes.first().map { it.nombre })
    }

    @Test
    fun renombrarActualizaReferencias() = runTest {
        repo.alternarFavorito(nota, esFavorito = false)
        repo.registrarReciente(nota)
        repo.rutaCambiada("/d/nota.txt", "/d/nueva.txt", "nueva.txt")
        assertEquals("/d/nueva.txt", repo.favoritos.first().single().ruta)
        assertEquals("nueva.txt", repo.recientes.first().single().nombre)
        repo.rutaCambiada("/d/nueva.txt", null, "nueva.txt")
        assertTrue(repo.favoritos.first().isEmpty())
    }

    @Test
    fun preferenciasPersisten() {
        assertEquals(Orden.NOMBRE, repo.orden)
        repo.orden = Orden.TAMANO
        repo.ascendente = false
        repo.ultimaCarpeta = "/d/Fotos"
        repo.paleta = "AZUL"
        assertEquals(Orden.TAMANO, repo.orden)
        assertEquals(false, repo.ascendente)
        assertEquals("/d/Fotos", repo.ultimaCarpeta)
        assertEquals("AZUL", repo.paleta)
    }
}
