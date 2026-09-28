package mx.ipn.escom.p3.gestor.ui

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.DriveFileMove
import androidx.compose.material.icons.automirrored.filled.Sort
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowDownward
import androidx.compose.material.icons.filled.ArrowUpward
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.ContentPaste
import androidx.compose.material.icons.filled.CreateNewFolder
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.filled.StarBorder
import androidx.compose.material.icons.filled.UploadFile
import androidx.compose.material3.AssistChip
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.ListItem
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import mx.ipn.escom.p3.gestor.dominio.EntradaArchivo
import mx.ipn.escom.p3.gestor.dominio.Orden
import mx.ipn.escom.p3.gestor.dominio.formatearTamano
import mx.ipn.escom.p3.gestor.plataforma.compartirArchivo
import mx.ipn.escom.p3.gestor.plataforma.formatearFecha
import mx.ipn.escom.p3.gestor.plataforma.rememberImportador

/**
 * Explorador jerárquico: ruta visible (migas), búsqueda, orden, menú
 * contextual (mantener presionado), deslizar para eliminar y deslizar hacia
 * abajo para actualizar.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PantallaExplorador(gestor: EstadoGestor, alAbrir: (EntradaArchivo) -> Unit) {
    val e by gestor.estado.collectAsState()
    val favoritas by gestor.rutasFavoritas.collectAsState()
    var dialogoCarpeta by remember { mutableStateOf(false) }
    var renombrando by remember { mutableStateOf<EntradaArchivo?>(null) }
    var eliminando by remember { mutableStateOf<EntradaArchivo?>(null) }
    var menuOrden by remember { mutableStateOf(false) }
    var menuNuevo by remember { mutableStateOf(false) }
    val importar = rememberImportador(e.rutaActual, gestor::importados)

    Column(Modifier.fillMaxSize()) {
        TopAppBar(
            title = { Text(e.migas.last().first, maxLines = 1, overflow = TextOverflow.Ellipsis) },
            navigationIcon = {
                if (!e.enRaiz) {
                    IconButton(onClick = gestor::subir) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Subir un nivel")
                    }
                }
            },
            actions = {
                Box {
                    IconButton(onClick = { menuOrden = true }) {
                        Icon(Icons.AutoMirrored.Filled.Sort, contentDescription = "Ordenar")
                    }
                    DropdownMenu(expanded = menuOrden, onDismissRequest = { menuOrden = false }) {
                        Orden.entries.forEach { o ->
                            DropdownMenuItem(
                                text = { Text(o.etiqueta) },
                                trailingIcon = {
                                    if (o == e.orden) {
                                        Icon(if (e.ascendente) Icons.Default.ArrowUpward else Icons.Default.ArrowDownward, null)
                                    }
                                },
                                onClick = { gestor.cambiarOrden(o); menuOrden = false },
                            )
                        }
                    }
                }
            },
            colors = TopAppBarDefaults.topAppBarColors(
                containerColor = MaterialTheme.colorScheme.primaryContainer,
                titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer,
            ),
        )

        // Raíces del sandbox (Documentos / Temporales).
        Row(Modifier.padding(horizontal = 12.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            gestor.raices.forEach { r ->
                FilterChip(selected = r == e.raiz, onClick = { gestor.cambiarRaiz(r) }, label = { Text(r.nombre) })
            }
        }

        // Ruta actual como migas de pan.
        LazyRow(
            contentPadding = PaddingValues(horizontal = 12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            itemsIndexed(e.migas) { i, (nombre, ruta) ->
                if (i > 0) Icon(Icons.Default.ChevronRight, null, Modifier.padding(horizontal = 2.dp))
                AssistChip(onClick = { gestor.abrirCarpeta(ruta) }, label = { Text(nombre) })
            }
        }

        OutlinedTextField(
            value = e.consulta,
            onValueChange = gestor::buscar,
            modifier = Modifier.fillMaxWidth().padding(horizontal = 12.dp, vertical = 4.dp),
            placeholder = { Text("Buscar en esta carpeta") },
            leadingIcon = { Icon(Icons.Default.Search, null) },
            trailingIcon = {
                if (e.consulta.isNotEmpty()) IconButton(onClick = { gestor.buscar("") }) { Icon(Icons.Default.Close, "Limpiar") }
            },
            singleLine = true,
        )

        e.portapapeles?.let { pp ->
            ListItem(
                headlineContent = { Text(if (pp.cortar) "Mover \"${pp.entrada.nombre}\"" else "Copiar \"${pp.entrada.nombre}\"") },
                supportingContent = { Text("Navega a la carpeta destino y pulsa Pegar") },
                leadingContent = { Icon(Icons.Default.ContentPaste, null) },
                trailingContent = {
                    Row {
                        IconButton(onClick = gestor::pegar) { Icon(Icons.Default.ContentPaste, "Pegar aquí") }
                        IconButton(onClick = gestor::cancelarPegar) { Icon(Icons.Default.Close, "Cancelar") }
                    }
                },
            )
        }

        Box(Modifier.weight(1f)) {
            PullToRefreshBox(isRefreshing = e.cargando, onRefresh = gestor::refrescar, modifier = Modifier.fillMaxSize()) {
                LazyColumn(Modifier.fillMaxSize(), contentPadding = PaddingValues(bottom = 88.dp)) {
                    if (e.entradas.isEmpty() && !e.cargando) {
                        item {
                            Text(
                                if (e.consulta.isBlank()) "Carpeta vacía" else "Sin resultados para \"${e.consulta}\"",
                                Modifier.fillMaxWidth().padding(32.dp),
                                style = MaterialTheme.typography.bodyLarge,
                            )
                        }
                    }
                    items(e.entradas, key = { it.ruta }) { entrada ->
                        FilaArchivo(
                            entrada = entrada,
                            favorito = entrada.ruta in favoritas,
                            alAbrir = { alAbrir(entrada) },
                            alRenombrar = { renombrando = entrada },
                            alEliminar = { eliminando = entrada },
                            gestor = gestor,
                        )
                        HorizontalDivider()
                    }
                }
            }
            Box(Modifier.align(Alignment.BottomEnd).padding(16.dp)) {
                FloatingActionButton(onClick = { menuNuevo = true }) { Icon(Icons.Default.Add, "Nuevo") }
                DropdownMenu(expanded = menuNuevo, onDismissRequest = { menuNuevo = false }) {
                    DropdownMenuItem(
                        text = { Text("Nueva carpeta") },
                        leadingIcon = { Icon(Icons.Default.CreateNewFolder, null) },
                        onClick = { menuNuevo = false; dialogoCarpeta = true },
                    )
                    DropdownMenuItem(
                        text = { Text("Importar archivos") },
                        leadingIcon = { Icon(Icons.Default.UploadFile, null) },
                        onClick = { menuNuevo = false; importar() },
                    )
                    if (e.portapapeles != null) {
                        DropdownMenuItem(
                            text = { Text("Pegar aquí") },
                            leadingIcon = { Icon(Icons.Default.ContentPaste, null) },
                            onClick = { menuNuevo = false; gestor.pegar() },
                        )
                    }
                }
            }
        }
    }

    if (dialogoCarpeta) {
        DialogoNombre("Nueva carpeta", "", alConfirmar = { gestor.crearCarpeta(it); dialogoCarpeta = false }) {
            dialogoCarpeta = false
        }
    }
    renombrando?.let { r ->
        DialogoNombre("Renombrar", r.nombre, alConfirmar = { gestor.renombrar(r, it); renombrando = null }) {
            renombrando = null
        }
    }
    eliminando?.let { x ->
        DialogoEliminar(x.nombre, alConfirmar = { gestor.eliminar(x); eliminando = null }) { eliminando = null }
    }
}

@OptIn(ExperimentalFoundationApi::class, ExperimentalMaterial3Api::class)
@Composable
private fun FilaArchivo(
    entrada: EntradaArchivo,
    favorito: Boolean,
    alAbrir: () -> Unit,
    alRenombrar: () -> Unit,
    alEliminar: () -> Unit,
    gestor: EstadoGestor,
) {
    var menu by remember { mutableStateOf(false) }
    // Deslizar a la izquierda pide confirmación en lugar de borrar directo.
    val deslizar = rememberSwipeToDismissBoxState(confirmValueChange = {
        if (it == SwipeToDismissBoxValue.EndToStart) alEliminar()
        false
    })

    SwipeToDismissBox(
        state = deslizar,
        enableDismissFromStartToEnd = false,
        backgroundContent = {
            Box(
                Modifier.fillMaxSize().background(MaterialTheme.colorScheme.errorContainer).padding(horizontal = 24.dp),
                contentAlignment = Alignment.CenterEnd,
            ) { Icon(Icons.Default.Delete, "Eliminar", tint = MaterialTheme.colorScheme.onErrorContainer) }
        },
    ) {
        Box {
            ListItem(
                modifier = Modifier.combinedClickable(onClick = alAbrir, onLongClick = { menu = true }),
                headlineContent = { Text(entrada.nombre, maxLines = 1, overflow = TextOverflow.Ellipsis) },
                supportingContent = {
                    Text(
                        (if (entrada.esCarpeta) "Carpeta" else formatearTamano(entrada.tamano)) +
                            " · " + formatearFecha(entrada.modificado),
                    )
                },
                leadingContent = {
                    Icon(iconoDe(entrada.tipo), null, tint = MaterialTheme.colorScheme.primary)
                },
                trailingContent = {
                    IconButton(onClick = { gestor.alternarFavorito(entrada) }) {
                        Icon(
                            if (favorito) Icons.Default.Star else Icons.Default.StarBorder,
                            if (favorito) "Quitar de favoritos" else "Agregar a favoritos",
                        )
                    }
                },
            )
            // Menú contextual al mantener presionado.
            DropdownMenu(expanded = menu, onDismissRequest = { menu = false }) {
                DropdownMenuItem(text = { Text("Renombrar") }, leadingIcon = { Icon(Icons.Default.Edit, null) },
                    onClick = { menu = false; alRenombrar() })
                DropdownMenuItem(text = { Text("Copiar") }, leadingIcon = { Icon(Icons.Default.ContentCopy, null) },
                    onClick = { menu = false; gestor.copiar(entrada, cortar = false) })
                DropdownMenuItem(text = { Text("Mover") }, leadingIcon = { Icon(Icons.AutoMirrored.Filled.DriveFileMove, null) },
                    onClick = { menu = false; gestor.copiar(entrada, cortar = true) })
                if (!entrada.esCarpeta) {
                    DropdownMenuItem(text = { Text("Compartir") }, leadingIcon = { Icon(Icons.Default.Share, null) },
                        onClick = { menu = false; compartirArchivo(entrada.ruta) })
                }
                DropdownMenuItem(text = { Text("Eliminar") }, leadingIcon = { Icon(Icons.Default.Delete, null) },
                    onClick = { menu = false; alEliminar() })
            }
        }
    }
}
