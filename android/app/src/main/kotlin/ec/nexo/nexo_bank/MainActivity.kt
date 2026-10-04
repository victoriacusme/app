package ec.nexo.nexo_bank

import android.content.pm.ApplicationInfo
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity: requerido por local_auth (BiometricPrompt).
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // En builds no depurables (release) la pantalla no se ve en el
        // selector de apps ni se puede capturar. En debug se permite para
        // poder grabar la demo.
        val debuggable = applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0
        if (!debuggable) {
            window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
        }
    }
}
