package com.example.frontend_account_system

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val NOTIFICATION_CHANNEL = "com.example.frontend_account_system/notifications"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannel()
        
        // CRITICAL: Handle notification intent when app is opened from terminated state
        handleNotificationIntent(intent)
    }
    
    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        handleNotificationIntent(intent)
    }
    
    private fun handleNotificationIntent(intent: android.content.Intent?) {
        if (intent != null && intent.extras != null) {
            val notificationId = intent.extras?.getString("notificationId")
            if (notificationId != null) {
                Log.d("NOTIFICATION_INTENT", "App opened from terminated notification: $notificationId")
                
                // Stop looping sound service
                SoundLoopService.stop(this)
                
                // Stop any ongoing notification sounds immediately
                val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                notificationManager.cancelAll()
                Log.d("NOTIFICATION_INTENT", "Stopped sound + cancelled all notifications")
                
                // Store for Flutter to process when ready
                intent.putExtra("pendingNotificationId", notificationId)
            }
        }
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Set up method channel for Flutter to get pending notification data
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPendingNotificationId" -> {
                    val pendingId = intent.getStringExtra("pendingNotificationId")
                    result.success(pendingId)
                    if (pendingId != null) {
                        // Clear after retrieving
                        intent.removeExtra("pendingNotificationId")
                        Log.d("NOTIFICATION_INTENT", "Retrieved and cleared pending notification: $pendingId")
                    }
                }
                "startSoundLoop" -> {
                    Log.d("SOUND_LOOP", "Starting sound loop service from Flutter")
                    SoundLoopService.start(this)
                    result.success(true)
                }
                "stopSoundLoop" -> {
                    Log.d("SOUND_LOOP", "Stopping sound loop service from Flutter")
                    SoundLoopService.stop(this)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = "meeting_notifications_v6"
            val channelName = "Meeting Notifications"
            val channelDescription = "Notifications for upcoming village bank meetings"

            val soundUri = Uri.parse(
                "android.resource://${packageName}/raw/meeting_sound"
            )

            val audioAttributes = AudioAttributes.Builder()
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setUsage(AudioAttributes.USAGE_NOTIFICATION)
                .build()

            val channel = NotificationChannel(
                channelId,
                channelName,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = channelDescription
                enableVibration(true)
                setSound(soundUri, audioAttributes)
            }

            val notificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}
