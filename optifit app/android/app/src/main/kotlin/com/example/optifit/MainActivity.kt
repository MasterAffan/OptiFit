package com.example.optifit

import android.os.Bundle
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "optifit/notification"
    private var initialIntent: Intent? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger, // This is guaranteed non-null here!
            CHANNEL
        ).setMethodCallHandler { call, result ->
            // No-op; Dart side listens, but native pushes notification
        }
        // Handle if the activity was started by a notification (cold start)
        initialIntent = intent
        handleIntent(initialIntent, flutterEngine)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent, flutterEngine!!)
    }

    private fun handleIntent(intent: Intent?, flutterEngine: FlutterEngine) {
        val payload = intent?.extras?.getString("payload")
        if (payload != null) {
            android.util.Log.d("OptiFitDebug", "handleIntent called, payload=$payload, flutterEngineNull=${flutterEngine == null}")
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
                .invokeMethod("onNotificationClick", payload)
        }
    }
}