package mx.ipn.escom.p3.gestor.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.gestures.rememberTransformableState
import androidx.compose.foundation.gestures.transformable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import mx.ipn.escom.p3.gestor.dominio.EntradaArchivo
import mx.ipn.escom.p3.gestor.dominio.TipoArchivo
import mx.ipn.escom.p3.gestor.dominio.formatearTamano
import mx.ipn.escom.p3.gestor.plataforma.compartirArchivo
import mx.ipn.escom.p3.gestor.plataforma.decodificarImagen
import mx.ipn.escom.p3.gestor.plataforma.formatearFecha

private sealed interface Contenido {
    data object Cargando : Contenido
    data class Texto(val texto: String) : Contenido
    data class Imagen(val imagen: ImageBitmap) : Contenido
    data class Error(val mensaje: String) : Contenido
}

/** Vista previa: texto, imagen con zoom/rotación, o aviso para tipos no soportados. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VisorArchivo(archivo: EntradaArchivo, gestor: EstadoGestor, alCerrar: () -> Unit) {
    var contenido by remember { mutableStateOf<Contenido>(Contenido.Cargando) }

    LaunchedEffect(archivo.ruta) {
        contenido = when (archivo.tipo) {
            TipoArchivo.TEXTO -> gestor.leerTexto(archivo).fold({ Contenido.Texto(it) }, { Contenido.Error(it.message ?: "Error") })
            TipoArchivo.IMAGEN -> gestor.leerBytes(archivo).fold(
                { bytes -> decodificarImagen(bytes)?.let { Contenido.Imagen(it) } ?: Contenido.Error("La imagen está dañada o su formato no es compatible.") },
                { Contenido.Error(it.message ?: "Error") },
            )
            // Se intenta como texto: si no lo es, se informa que no hay vista previa.
            else -> gestor.leerTexto(archivo).fold(
                { Contenido.Texto(it) },
                { Contenido.Error("No hay vista previa para este tipo de archivo (.${archivo.extension}). Puedes compartirlo para abrirlo con otra app.") },
            )
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(archivo.nombre) },
                navigationIcon = { IconButton(onClick = alCerrar) { Icon(Icons.AutoMirrored.Filled.ArrowBack, "Volver") } },
                actions = { IconButton(onClick = { compartirArchivo(archivo.ruta) }) { Icon(Icons.Default.Share, "Compartir") } },
            )
        },
    ) { relleno ->
        Box(Modifier.fillMaxSize().padding(relleno), contentAlignment = Alignment.Center) {
            when (val c = contenido) {
                Contenido.Cargando -> CircularProgressIndicator()
                is Contenido.Texto -> SelectionContainer {
                    Text(
                        c.texto,
                        Modifier.fillMaxSize().verticalScroll(rememberScrollState()).horizontalScroll(rememberScrollState()).padding(16.dp),
                        fontFamily = FontFamily.Monospace,
                        style = MaterialTheme.typography.bodyMedium,
                    )
                }
                is Contenido.Imagen -> ImagenConZoom(c.imagen)
                is Contenido.Error -> Column(Modifier.padding(32.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(Icons.Default.Warning, null, tint = MaterialTheme.colorScheme.error)
                    Text(c.mensaje, Modifier.padding(top = 8.dp))
                    Text(
                        "${formatearTamano(archivo.tamano)} · ${formatearFecha(archivo.modificado)}",
                        Modifier.padding(top = 8.dp),
                        style = MaterialTheme.typography.bodySmall,
                    )
                }
            }
        }
    }
}

/** Pellizcar para zoom, girar con dos dedos, arrastrar; doble toque ajusta a pantalla. */
@Composable
private fun ImagenConZoom(imagen: ImageBitmap) {
    var escala by remember { mutableFloatStateOf(1f) }
    var giro by remember { mutableFloatStateOf(0f) }
    var desplazamiento by remember { mutableStateOf(Offset.Zero) }
    val estado = rememberTransformableState { zoom, mover, rotar ->
        escala = (escala * zoom).coerceIn(1f, 6f)
        giro += rotar
        desplazamiento += mover
    }
    Image(
        bitmap = imagen,
        contentDescription = "Imagen",
        contentScale = ContentScale.Fit,
        modifier = Modifier
            .fillMaxSize()
            .pointerInput(Unit) {
                detectTapGestures(onDoubleTap = { escala = 1f; giro = 0f; desplazamiento = Offset.Zero })
            }
            .transformable(estado)
            .graphicsLayer(
                scaleX = escala,
                scaleY = escala,
                rotationZ = giro,
                translationX = desplazamiento.x,
                translationY = desplazamiento.y,
            ),
    )
}
