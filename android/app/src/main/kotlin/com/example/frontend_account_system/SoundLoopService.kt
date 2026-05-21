package com.example.frontend_account_system

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * Foreground Service that loops meeting_sound.wav until explicitly stopped.
 * Works in both foreground and background states.
 */
class SoundLoopService : Service() {
    
    companion object {
        private const val TAG = "SoundLoopService"
        private const val CHANNEL_ID = "sound_loop_service_channel"
        private const val NOTIFICATION_ID = 99999
        
        fun start(context: Context) {
            val intent = Intent(context, SoundLoopService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
            Log.d(TAG, "Service start requested")
        }
        
        fun stop(context: Context) {
            val intent = Intent(context, SoundLoopService::class.java)
            context.stopService(intent)
            Log.d(TAG, "Service stop requested")
        }
    }
    
    private var mediaPlayer: MediaPlayer? = null
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service created")
        createServiceChannel()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "onStartCommand")
        
        // Start as foreground service with a minimal notification
        val notification = buildNotification()
        startForeground(NOTIFICATION_ID, notification)
        
        // Start looping sound
        startSound()
        
        return START_STICKY
    }
    
    override fun onDestroy() {
        Log.d(TAG, "Service destroyed — stopping sound")
        stopSound()
        super.onDestroy()
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    private fun startSound() {
        if (mediaPlayer != null) {
            Log.d(TAG, "MediaPlayer already active, skipping")
            return
        }
        
        try {
            val soundUri = Uri.parse("android.resource://$packageName/raw/meeting_sound")
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .build()
                )
                setDataSource(applicationContext, soundUri)
                isLooping = true
                prepare()
                start()
            }
            Log.d(TAG, "Sound loop started")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start sound: ${e.message}")
        }
    }
    
    private fun stopSound() {
        try {
            mediaPlayer?.stop()
            mediaPlayer?.release()
            mediaPlayer = null
            Log.d(TAG, "Sound loop stopped")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop sound: ${e.message}")
        }
    }
    
    private fun createServiceChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Sound Loop Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Keeps notification sound playing"
                setSound(null, null) // Silent channel for the service itself
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }
    
    private fun buildNotification(): Notification {
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("ແຈ້ງເຕືອນການປະຊຸມ")
            .setContentText("ມີການແຈ້ງເຕືອນໃໝ່")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .build()
    }
}
