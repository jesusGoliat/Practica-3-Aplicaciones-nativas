package mx.ipn.escom.p3.gestor.ui

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.InsertDriveFile
import androidx.compose.material.icons.filled.AudioFile
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Folder
import androidx.compose.material.icons.filled.FolderZip
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.PictureAsPdf
import androidx.compose.material.icons.filled.VideoFile
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.graphics.vector.ImageVector
import mx.ipn.escom.p3.gestor.dominio.TipoArchivo
import mx.ipn.escom.p3.gestor.dominio.validarNombre

/** Ícono según el tipo de archivo. */
fun iconoDe(tipo: TipoArchivo): ImageVector = when (tipo) {
    TipoArchivo.CARPETA -> Icons.Default.Folder
    TipoArchivo.TEXTO -> Icons.Default.Description
    TipoArchivo.IMAGEN -> Icons.Default.Image
    TipoArchivo.AUDIO -> Icons.Default.AudioFile
    TipoArchivo.VIDEO -> Icons.Default.VideoFile
    TipoArchivo.PDF -> Icons.Default.PictureAsPdf
    TipoArchivo.COMPRIMIDO -> Icons.Default.FolderZip
    TipoArchivo.OTRO -> Icons.AutoMirrored.Filled.InsertDriveFile
}

/** Diálogo para escribir un nombre (crear carpeta o renombrar). */
@Composable
fun DialogoNombre(titulo: String, inicial: String, alConfirmar: (String) -> Unit, alCancelar: () -> Unit) {
    var texto by remember { mutableStateOf(inicial) }
    val error = if (texto == inicial && inicial.isEmpty()) null else validarNombre(texto)
    AlertDialog(
        onDismissRequest = alCancelar,
        title = { Text(titulo) },
        text = {
            OutlinedTextField(
                value = texto,
                onValueChange = { texto = it },
                singleLine = true,
                label = { Text("Nombre") },
                isError = error != null,
                supportingText = { error?.let { Text(it) } },
            )
        },
        confirmButton = {
            TextButton(enabled = validarNombre(texto) == null, onClick = { alConfirmar(texto) }) { Text("Aceptar") }
        },
        dismissButton = { TextButton(onClick = alCancelar) { Text("Cancelar") } },
    )
}

/** Confirmación antes de eliminar. */
@Composable
fun DialogoEliminar(nombre: String, alConfirmar: () -> Unit, alCancelar: () -> Unit) {
    AlertDialog(
        onDismissRequest = alCancelar,
        title = { Text("¿Eliminar \"$nombre\"?") },
        text = { Text("Se borrará del dispositivo. Esta acción no se puede deshacer.") },
        confirmButton = { TextButton(onClick = alConfirmar) { Text("Eliminar") } },
        dismissButton = { TextButton(onClick = alCancelar) { Text("Cancelar") } },
    )
}
