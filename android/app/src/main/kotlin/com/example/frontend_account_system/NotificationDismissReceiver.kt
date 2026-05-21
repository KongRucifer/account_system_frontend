package com.example.frontend_account_system

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * BroadcastReceiver that fires when a notification is swiped away / dismissed.
 * Stops the SoundLoopService so the looping sound stops.
 */
class NotificationDismissReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "NotifDismissReceiver"
        const val ACTION_NOTIFICATION_DISMISSED = 
            "com.example.frontend_account_system.NOTIFICATION_DISMISSED"
    }
    
    override fun onReceive(context: Context?, intent: Intent?) {
        Log.d(TAG, "Notification dismissed — stopping sound loop service")
        context?.let {
            SoundLoopService.stop(it)
        }
    }
}
