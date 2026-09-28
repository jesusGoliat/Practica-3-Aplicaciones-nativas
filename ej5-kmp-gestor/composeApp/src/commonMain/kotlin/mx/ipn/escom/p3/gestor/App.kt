package mx.ipn.escom.p3.gestor

import androidx.compose.animation.AnimatedContent
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Folder
import androidx.compose.material.icons.filled.History
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import kotlinx.coroutines.launch
import mx.ipn.escom.p3.gestor.datos.RepositorioGestor
import mx.ipn.escom.p3.gestor.datos.sembrarEjemplos
import mx.ipn.escom.p3.gestor.dominio.EntradaArchivo
import mx.ipn.escom.p3.gestor.plataforma.ManejarAtras
import mx.ipn.escom.p3.gestor.plataforma.SistemaArchivos
import mx.ipn.escom.p3.gestor.plataforma.ahoraMillis
import mx.ipn.escom.p3.gestor.plataforma.crearDriver
import mx.ipn.escom.p3.gestor.ui.EstadoGestor
import mx.ipn.escom.p3.gestor.ui.PantallaAjustes
import mx.ipn.escom.p3.gestor.ui.PantallaExplorador
import mx.ipn.escom.p3.gestor.ui.PantallaMarcadores
import mx.ipn.escom.p3.gestor.ui.TemaGestor
import mx.ipn.escom.p3.gestor.ui.VisorArchivo

private enum class Seccion(val etiqueta: String, val icono: ImageVector) {
    ARCHIVOS("Archivos", Icons.Default.Folder),
    FAVORITOS("Favoritos", Icons.Default.Star),
    RECIENTES("Recientes", Icons.Default.History),
    AJUSTES("Ajustes", Icons.Default.Settings),
}

/** Punto de entrada común: lo llaman MainActivity (Android) y MainViewController (iOS). */
@Composable
fun App() {
    val alcance = rememberCoroutineScope()
    val gestor = remember {
        val fs = SistemaArchivos()
        val repo = RepositorioGestor(crearDriver(), reloj = ::ahoraMillis)
        EstadoGestor(fs, repo, alcance).also { g ->
            alcance.launch { sembrarEjemplos(fs, repo, g.raices.first().ruta); g.refrescar() }
        }
    }
    val paleta by gestor.paleta.collectAsState()

    TemaGestor(paleta) {
        var seccion by rememberSaveable { mutableStateOf(Seccion.ARCHIVOS) }
        var abierto by remember { mutableStateOf<EntradaArchivo?>(null) }
        val avisos = remember { SnackbarHostState() }
        val estado by gestor.estado.collectAsState()

        LaunchedEffect(estado.mensaje) {
            estado.mensaje?.let { avisos.showSnackbar(it); gestor.mensajeMostrado() }
        }

        fun abrir(e: EntradaArchivo) {
            if (e.esCarpeta) {
                gestor.abrirCarpeta(e.ruta)
                seccion = Seccion.ARCHIVOS
            } else {
                gestor.abrioArchivo(e)
                abierto = e
            }
        }

        ManejarAtras(activo = abierto != null || (seccion == Seccion.ARCHIVOS && !estado.enRaiz)) {
            if (abierto != null) abierto = null else gestor.subir()
        }

        val visor = abierto
        if (visor != null) {
            VisorArchivo(visor, gestor, alCerrar = { abierto = null })
            return@TemaGestor
        }

        Scaffold(
            snackbarHost = { SnackbarHost(avisos) },
            bottomBar = {
                NavigationBar {
                    Seccion.entries.forEach { s ->
                        NavigationBarItem(
                            selected = s == seccion,
                            onClick = { seccion = s },
                            icon = { Icon(s.icono, contentDescription = null) },
                            label = { Text(s.etiqueta) },
                        )
                    }
                }
            },
        ) { relleno ->
            AnimatedContent(seccion, Modifier.padding(relleno), label = "seccion") { s ->
                when (s) {
                    Seccion.ARCHIVOS -> PantallaExplorador(gestor, alAbrir = ::abrir)
                    Seccion.FAVORITOS -> PantallaMarcadores(gestor, favoritos = true, alAbrir = ::abrir)
                    Seccion.RECIENTES -> PantallaMarcadores(gestor, favoritos = false, alAbrir = ::abrir)
                    Seccion.AJUSTES -> PantallaAjustes(gestor)
                }
            }
        }
    }
}
