package com.example.frontend_account_system

import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

/**
 * Custom FirebaseMessagingService that starts the SoundLoopService
 * when a data-only FCM message arrives while the app is in background/terminated.
 * This ensures the looping sound plays even when Flutter's background isolate
 * cannot access MethodChannel.
 */
class MyFirebaseMessagingService : FirebaseMessagingService() {
    
    companion object {
        private const val TAG = "MyFCMService"
    }
    
    override fun onMessageReceived(message: RemoteMessage) {
        Log.d(TAG, "FCM message received: ${message.data}")
        
        val notificationId = message.data["notificationId"]
        if (notificationId != null && notificationId.isNotEmpty()) {
            Log.d(TAG, "Starting SoundLoopService for notification: $notificationId")
            // Start looping sound via native Foreground Service
            SoundLoopService.start(this)
        }
        
        // Let Flutter's background handler also process the message
        super.onMessageReceived(message)
    }
    
    override fun onNewToken(token: String) {
        Log.d(TAG, "New FCM token: ${token.take(20)}...")
        super.onNewToken(token)
    }
}
