package mx.ipn.escom.p3.gestor

import android.app.Application
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import mx.ipn.escom.p3.gestor.plataforma.ContextoAndroid

/** Guarda el contexto de la aplicación para las implementaciones `actual`. */
class GestorApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        ContextoAndroid.app = this
    }
}

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
        setContent { App() }
    }
}
