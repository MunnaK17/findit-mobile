package com.findit.campus.findit_mobile

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Channel untuk push FCM (channel_id "findit_updates" dikirim oleh Edge Function notify-email).
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "findit_updates",
                "Kabar laporan & klaim",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply { description = "Laporan diverifikasi, klaim masuk, dan klaim disetujui" }
            getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
    }
}
