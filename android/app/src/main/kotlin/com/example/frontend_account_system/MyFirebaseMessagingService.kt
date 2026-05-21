package com.example.frontend_account_system

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.net.Uri
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

/**
 * Custom FirebaseMessagingService that:
 * 1. Starts the SoundLoopService for looping sound
 * 2. Shows a notification with deleteIntent so swiping it away stops the sound
 */
class MyFirebaseMessagingService : FirebaseMessagingService() {
    
    companion object {
        private const val TAG = "MyFCMService"
        private const val CHANNEL_ID = "meeting_notifications_v6"
    }
    
    override fun onMessageReceived(message: RemoteMessage) {
        Log.d(TAG, "FCM message received: ${message.data}")
        
        val notificationId = message.data["notificationId"]
        val title = message.data["title"] ?: "ແຈ້ງເຕືອນ"
        val body = message.data["body"] ?: ""
        
        if (notificationId != null && notificationId.isNotEmpty()) {
            Log.d(TAG, "Starting SoundLoopService for notification: $notificationId")
            // Start looping sound via native Foreground Service
            SoundLoopService.start(this)
            
            // Show notification with dismiss handler
            showNotificationWithDismissHandler(notificationId, title, body)
        }
        
        // Let Flutter's background handler also process the message
        super.onMessageReceived(message)
    }
    
    override fun onNewToken(token: String) {
        Log.d(TAG, "New FCM token: ${token.take(20)}...")
        super.onNewToken(token)
    }
    
    private fun showNotificationWithDismissHandler(
        notificationId: String,
        title: String,
        body: String
    ) {
        val androidNotifId = notificationId.hashCode().and(0x7FFFFFFF) % 100000
        
        // Intent for when notification is tapped → open app + stop sound
        val tapIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("notificationId", notificationId)
        }
        val tapPendingIntent = PendingIntent.getActivity(
            this, androidNotifId, tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Intent for when notification is swiped away → stop sound
        val dismissIntent = Intent(this, NotificationDismissReceiver::class.java).apply {
            action = NotificationDismissReceiver.ACTION_NOTIFICATION_DISMISSED
        }
        val dismissPendingIntent = PendingIntent.getBroadcast(
            this, androidNotifId, dismissIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        val soundUri = Uri.parse("android.resource://$packageName/raw/meeting_sound")
        
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setSound(soundUri)
            .setVibrate(longArrayOf(0, 500, 200, 500))
            .setAutoCancel(true)
            .setContentIntent(tapPendingIntent)
            .setDeleteIntent(dismissPendingIntent)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(tapPendingIntent, true)
            .build()
        
        val manager = getSystemService(NotificationManager::class.java)
        manager.notify(androidNotifId, notification)
        Log.d(TAG, "Notification shown with dismiss handler: id=$androidNotifId")
    }
}
