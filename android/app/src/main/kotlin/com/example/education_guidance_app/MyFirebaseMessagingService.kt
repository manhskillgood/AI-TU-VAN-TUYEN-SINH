package com.example.education_guidance_app

import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MyFirebaseMessagingService : FirebaseMessagingService() {
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        // Minimal handling: log message for debug.
        Log.d("MyFirebaseMsgService", "From: ${remoteMessage.from}")
        remoteMessage.notification?.let {
            Log.d("MyFirebaseMsgService", "Notification Message Body: ${it.body}")
        }
    }

    override fun onNewToken(token: String) {
        Log.d("MyFirebaseMsgService", "Refreshed token: $token")
        // You may want to send token to app server here.
    }
}
