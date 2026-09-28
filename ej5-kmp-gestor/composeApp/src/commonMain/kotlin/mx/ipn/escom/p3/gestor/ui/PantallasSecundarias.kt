package mx.ipn.escom.p3.gestor.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.background
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CloudOff
import androidx.compose.material.icons.filled.DeleteSweep
import androidx.compose.material.icons.filled.Info
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import mx.ipn.escom.p3.gestor.dominio.TipoArchivo
import mx.ipn.escom.p3.gestor.dominio.EntradaArchivo
import mx.ipn.escom.p3.gestor.plataforma.formatearFecha
import mx.ipn.escom.p3.gestor.plataforma.nombrePlataforma

/** Lista de favoritos o recientes (persistidos con SQLDelight). */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PantallaMarcadores(gestor: EstadoGestor, favoritos: Boolean, alAbrir: (EntradaArchivo) -> Unit) {
    val lista by (if (favoritos) gestor.favoritos else gestor.recientes).collectAsState()
    Column(Modifier.fillMaxSize()) {
        TopAppBar(
            title = { Text(if (favoritos) "Favoritos" else "Recientes") },
            actions = {
                if (!favoritos && lista.isNotEmpty()) {
                    IconButton(onClick = gestor::limpiarRecientes) { Icon(Icons.Default.DeleteSweep, "Limpiar historial") }
                }
            },
        )
        if (lista.isEmpty()) {
            Text(
                if (favoritos) "Marca archivos o carpetas con la estrella para verlos aquí." else "Los archivos que abras aparecerán aquí.",
                Modifier.padding(32.dp),
            )
        }
        LazyColumn {
            items(lista, key = { it.ruta }) { m ->
                // Si el archivo ya no existe se muestra deshabilitado.
                val info = gestor.infoDe(m.ruta)
                ListItem(
                    modifier = Modifier.clickable(enabled = info != null) { info?.let(alAbrir) },
                    headlineContent = { Text(m.nombre) },
                    supportingContent = {
                        Text(if (info == null) "No disponible" else m.ruta.substringAfterLast("/Documentos").ifEmpty { m.ruta })
                    },
                    leadingContent = {
                        Icon(iconoDe(info?.tipo ?: if (m.esCarpeta) TipoArchivo.CARPETA else TipoArchivo.OTRO), null)
                    },
                    trailingContent = { Text(formatearFecha(m.fecha), style = MaterialTheme.typography.bodySmall) },
                )
                HorizontalDivider()
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PantallaAjustes(gestor: EstadoGestor) {
    val paleta by gestor.paleta.collectAsState()
    Column(Modifier.fillMaxSize()) {
        TopAppBar(title = { Text("Ajustes") })
        Text("Tema", Modifier.padding(16.dp), color = MaterialTheme.colorScheme.primary, style = MaterialTheme.typography.titleSmall)
        Paleta.entries.forEach { p ->
            ListItem(
                modifier = Modifier.fillMaxWidth().selectable(selected = p == paleta, onClick = { gestor.cambiarPaleta(p) }),
                headlineContent = { Text(p.etiqueta) },
                supportingContent = { Text("Se adapta al modo claro u oscuro del sistema") },
                leadingContent = { Box(Modifier.size(32.dp).background(p.base, CircleShape)) },
                trailingContent = { RadioButton(selected = p == paleta, onClick = { gestor.cambiarPaleta(p) }) },
            )
        }
        HorizontalDivider()
        ListItem(
            headlineContent = { Text("Funciona sin conexión") },
            supportingContent = { Text("Archivos en el sandbox de la app; favoritos, recientes y preferencias en SQLite (SQLDelight).") },
            leadingContent = { Icon(Icons.Default.CloudOff, null) },
        )
        ListItem(
            headlineContent = { Text("Gestor KMP 1.0") },
            supportingContent = { Text("Práctica 3 · ESCOM-IPN · $nombrePlataforma") },
            leadingContent = { Icon(Icons.Default.Info, null) },
        )
    }
}
