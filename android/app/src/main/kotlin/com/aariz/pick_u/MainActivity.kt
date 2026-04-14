package com.aariz.pick_u

import android.app.NotificationManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private val channelName = "picku.notification_debug"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAndroidNotificationChannelInfo" -> {
                        val channelId = call.argument<String>("channelId")
                        if (channelId.isNullOrBlank()) {
                            result.error("bad_args", "channelId is required", null)
                            return@setMethodCallHandler
                        }

                        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
                            result.success(
                                mapOf(
                                    "sdkInt" to Build.VERSION.SDK_INT,
                                    "supported" to false,
                                    "reason" to "NotificationChannel not supported below Android 8"
                                )
                            )
                            return@setMethodCallHandler
                        }

                        try {
                            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                            val ch = nm.getNotificationChannel(channelId)
                            if (ch == null) {
                                result.success(
                                    mapOf(
                                        "sdkInt" to Build.VERSION.SDK_INT,
                                        "supported" to true,
                                        "exists" to false,
                                        "channelId" to channelId
                                    )
                                )
                                return@setMethodCallHandler
                            }

                            val soundUri = ch.sound?.toString()
                            val importance = ch.importance
                            val canBypassDnd = ch.canBypassDnd()
                            val shouldVibrate = ch.shouldVibrate()
                            val vibrationPattern = ch.vibrationPattern?.toList()
                            val lockscreenVisibility = ch.lockscreenVisibility
                            val isBlocked = importance == NotificationManager.IMPORTANCE_NONE

                            result.success(
                                mapOf(
                                    "sdkInt" to Build.VERSION.SDK_INT,
                                    "supported" to true,
                                    "exists" to true,
                                    "channelId" to ch.id,
                                    "name" to ch.name?.toString(),
                                    "description" to ch.description,
                                    "importance" to importance,
                                    "isBlocked" to isBlocked,
                                    "soundUri" to soundUri,
                                    "canBypassDnd" to canBypassDnd,
                                    "shouldVibrate" to shouldVibrate,
                                    "vibrationPattern" to vibrationPattern,
                                    "lockscreenVisibility" to lockscreenVisibility
                                )
                            )
                        } catch (e: Exception) {
                            result.error("exception", e.message, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
