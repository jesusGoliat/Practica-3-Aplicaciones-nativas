package mx.ipn.escom.p3.gestor.ui

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

/** Temas personalizables de la práctica, cada uno con variante clara y oscura. */
enum class Paleta(val etiqueta: String, val base: Color, val claro: ColorScheme, val oscuro: ColorScheme) {
    GUINDA(
        "Guinda IPN",
        Color(0xFF6C1D45),
        lightColorScheme(
            primary = Color(0xFF6C1D45), onPrimary = Color.White,
            primaryContainer = Color(0xFFFFD9E4), onPrimaryContainer = Color(0xFF3E0021),
            secondary = Color(0xFF745660), secondaryContainer = Color(0xFFFFD9E3),
            tertiary = Color(0xFF7C5635),
        ),
        darkColorScheme(
            primary = Color(0xFFFFB0CB), onPrimary = Color(0xFF5B1138),
            primaryContainer = Color(0xFF6C1D45), onPrimaryContainer = Color(0xFFFFD9E4),
            secondary = Color(0xFFE2BDC7), secondaryContainer = Color(0xFF5B3F48),
            tertiary = Color(0xFFEFBD94),
        ),
    ),
    AZUL(
        "Azul ESCOM",
        Color(0xFF003B5C),
        lightColorScheme(
            primary = Color(0xFF003B5C), onPrimary = Color.White,
            primaryContainer = Color(0xFFCCE5FF), onPrimaryContainer = Color(0xFF001D31),
            secondary = Color(0xFF50606F), secondaryContainer = Color(0xFFD3E4F6),
            tertiary = Color(0xFF66587B),
        ),
        darkColorScheme(
            primary = Color(0xFF93CCFF), onPrimary = Color(0xFF003352),
            primaryContainer = Color(0xFF004A74), onPrimaryContainer = Color(0xFFCCE5FF),
            secondary = Color(0xFFB7C8DA), secondaryContainer = Color(0xFF384956),
            tertiary = Color(0xFFD1BFE7),
        ),
    );

    companion object {
        fun porNombre(n: String) = entries.firstOrNull { it.name == n } ?: GUINDA
    }
}

/** Aplica la paleta y se adapta automáticamente al modo claro/oscuro del sistema. */
@Composable
fun TemaGestor(paleta: Paleta, contenido: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = if (isSystemInDarkTheme()) paleta.oscuro else paleta.claro,
        content = contenido,
    )
}
