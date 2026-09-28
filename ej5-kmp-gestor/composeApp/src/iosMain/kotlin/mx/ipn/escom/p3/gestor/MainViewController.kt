package mx.ipn.escom.p3.gestor

import androidx.compose.ui.window.ComposeUIViewController
import platform.UIKit.UIViewController

/** Lo llama ContentView.swift (iosApp) para mostrar la interfaz compartida. */
fun MainViewController(): UIViewController = ComposeUIViewController { App() }
