package mx.ipn.escom.p3.gestor

import mx.ipn.escom.p3.gestor.dominio.EntradaArchivo
import mx.ipn.escom.p3.gestor.dominio.Orden
import mx.ipn.escom.p3.gestor.dominio.Raiz
import mx.ipn.escom.p3.gestor.dominio.TipoArchivo
import mx.ipn.escom.p3.gestor.dominio.filtrar
import mx.ipn.escom.p3.gestor.dominio.formatearTamano
import mx.ipn.escom.p3.gestor.dominio.nombreLibre
import mx.ipn.escom.p3.gestor.dominio.ordenar
import mx.ipn.escom.p3.gestor.dominio.padreDe
import mx.ipn.escom.p3.gestor.dominio.validarNombre
import mx.ipn.escom.p3.gestor.ui.EstadoExplorador
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNotNull
import kotlin.test.assertNull

/** Pruebas de la lógica compartida (commonMain); corren igual en Android e iOS. */
class DominioTest {
    private fun archivo(nombre: String, tam: Long = 0, fecha: Long = 0, carpeta: Boolean = false) =
        EntradaArchivo("/d/$nombre", nombre, carpeta, tam, fecha)

    private val lista = listOf(
        archivo("b.txt", tam = 300, fecha = 3),
        archivo("Fotos", carpeta = true, fecha = 1),
        archivo("a.png", tam = 900, fecha = 2),
        archivo("C.md", tam = 10, fecha = 5),
    )

    @Test
    fun ordenaCarpetasPrimeroYPorNombre() {
        assertEquals(listOf("Fotos", "a.png", "b.txt", "C.md"), ordenar(lista, Orden.NOMBRE, true).map { it.nombre })
    }

    @Test
    fun ordenaPorTamanoDescendente() {
        assertEquals(listOf("Fotos", "a.png", "b.txt", "C.md"), ordenar(lista, Orden.TAMANO, false).map { it.nombre })
    }

    @Test
    fun ordenaPorFecha() {
        assertEquals(listOf("Fotos", "a.png", "b.txt", "C.md"), ordenar(lista, Orden.FECHA, true).map { it.nombre })
    }

    @Test
    fun filtraSinDistinguirMayusculas() {
        assertEquals(listOf("C.md"), filtrar(lista, "c.M").map { it.nombre })
        assertEquals(4, filtrar(lista, "  ").size)
    }

    @Test
    fun detectaTipoPorExtension() {
        assertEquals(TipoArchivo.IMAGEN, archivo("x.JPG").tipo)
        assertEquals(TipoArchivo.TEXTO, archivo("App.swift").tipo)
        assertEquals(TipoArchivo.OTRO, archivo("datos.bin").tipo)
        assertEquals(TipoArchivo.CARPETA, archivo("x.txt", carpeta = true).tipo)
    }

    @Test
    fun generaNombreLibre() {
        val existentes = setOf("foto.png", "foto (1).png", "notas")
        assertEquals("foto (2).png", nombreLibre("foto.png") { it in existentes })
        assertEquals("notas (1)", nombreLibre("notas") { it in existentes })
        assertEquals("nuevo.txt", nombreLibre("nuevo.txt") { it in existentes })
    }

    @Test
    fun validaNombres() {
        assertNotNull(validarNombre(""))
        assertNotNull(validarNombre("a/b"))
        assertNotNull(validarNombre(".."))
        assertNull(validarNombre("Práctica 3"))
    }

    @Test
    fun formateaTamanos() {
        assertEquals("512 B", formatearTamano(512))
        assertEquals("1.5 KB", formatearTamano(1536))
        assertEquals("2.0 MB", formatearTamano(2L * 1024 * 1024))
    }

    @Test
    fun calculaMigasYPadre() {
        val e = EstadoExplorador(Raiz("Documentos", "/app/Documentos"), "/app/Documentos/Fotos/2026")
        assertEquals(listOf("Documentos", "Fotos", "2026"), e.migas.map { it.first })
        assertEquals("/app/Documentos/Fotos", e.migas[1].second)
        assertEquals("/app/Documentos/Fotos", padreDe(e.rutaActual))
    }
}
