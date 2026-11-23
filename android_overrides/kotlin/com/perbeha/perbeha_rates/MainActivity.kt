package com.perbeha.perbeha_rates

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // A rates board must never dim or go to sleep.
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val prefs = getSharedPreferences("perbeha_rates", MODE_PRIVATE)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "perbeha/store")
            .setMethodCallHandler { call, result ->
                val key = call.argument<String>("key")
                when {
                    key == null -> result.error("NO_KEY", "key is required", null)
                    call.method == "get" -> result.success(prefs.getString(key, null))
                    call.method == "set" -> {
                        // commit() writes to disk right away, so a power cut can't lose new rates.
                        val ok = prefs.edit().putString(key, call.argument<String>("value")).commit()
                        result.success(ok)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
