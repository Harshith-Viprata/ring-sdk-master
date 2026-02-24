package com.yucheng.healthwear_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "ycaviation.com/yc_product_plugin_method_channel"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
    }

    override fun onPause() {
        super.onPause()
        methodChannel?.invokeMethod("pauseEventChannel", null)
    }

    override fun onResume() {
        super.onResume()
        methodChannel?.invokeMethod("resumeEventChannel", null)
    }

    override fun onDestroy() {
        super.onDestroy()
        methodChannel?.invokeMethod("shutdownBle", null)
    }
}
