package com.toobjod.budgetPlanner.notification

import android.app.Notification
import android.content.ComponentName
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.plugin.common.EventChannel
import org.json.JSONArray
import org.json.JSONObject

class BankNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "BankNotifListener"
        private const val PREFS_NAME = "toobjod_notification_prefs"
        private const val KEY_PENDING_NOTIFS = "pending_bank_notifications"
        private const val MAX_BUFFER_SIZE = 50
        private const val DEBOUNCE_WINDOW_MS = 4000L

        var eventSink: EventChannel.EventSink? = null
        var isServiceConnected: Boolean = false

        // Cache recent notifications to debounce rapid multi-dispatch from Android OS
        private val recentNotifCache = object : LinkedHashMap<String, Long>(50, 0.75f, true) {
            override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, Long>?): Boolean {
                return size > 100
            }
        }

        val SUPPORTED_PACKAGES = setOf(
            "com.kasikorn.retail.mbanking.wap", // K PLUS (Official)
            "com.kasikorn.bank",                // K PLUS (Alias)
            "com.kasikornbank.kplus",           // K PLUS (Alias)
            "com.scb.phone",                    // SCB EASY (Official)
            "com.scb.easy",                     // SCB EASY (Alias)
            "ktbcs.netbank",                    // Krungthai NEXT (Official)
            "ktb.cs.mobile.app",                // Krungthai NEXT (Alias)
            "com.ktb.customer.qr",              // Paotang / G-Wallet (Official)
            "com.bbl.mBanking",                 // Bangkok Bank (Official)
            "com.bbl.mobilephone",              // Bangkok Bank (Alias)
            "com.ttbbank.oneapp",               // ttb touch (Official)
            "com.tmb.mbanking",                 // ttb touch (Alias)
            "com.krungsri.kma",                 // KMA Krungsri (Official)
            "com.bay.mbanking",                 // KMA Krungsri (Alias)
            "th.co.truemoney.wallet",           // TrueMoney (Official)
            "com.shopeepay.th",                 // ShopeePay (Official)
            "com.airpay",                       // ShopeePay (Alias)
            "com.kasikornbank.make",            // MAKE by KBank (Official)
            "com.kbank.make",                   // MAKE by KBank (Alias)
            "com.gsb.mymo",                     // MyMo GSB (Official)
            "com.my.mymo",                      // MyMo GSB (Alias)
            "co.th.dime",                       // Dime! by KKP
            "com.krungsri.kept",                // Kept by Krungsri
            "com.cimbthai.digital",             // CIMB THAI
            "com.uob.mightyth",                 // UOB TMRW
            "com.google.android.apps.messaging", // Google Messages (SMS)
            "com.samsung.android.messaging",     // Samsung Messages (SMS)
            "com.android.mms",                   // Android MMS/SMS
            "com.android.shell"                 // ADB Shell command testing
        )

        /**
         * Robust Rebind Mechanism:
         * 1. Uses requestRebind on Android 7+ (API 24+)
         * 2. Uses Component Enabled State toggle to force Android NotificationManagerService
         *    to reconnect the listener if Android OS dropped it in the background.
         */
        @Synchronized
        fun rebindService(context: Context): Boolean {
            return try {
                val cn = ComponentName(context, BankNotificationListenerService::class.java)
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    NotificationListenerService.requestRebind(cn)
                    Log.i(TAG, "🔄 [BankNotifListener] requestRebind called successfully.")
                }

                // Component toggling trick to kickstart NotificationManagerService
                val pm = context.packageManager
                pm.setComponentEnabledSetting(
                    cn,
                    android.content.pm.PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    android.content.pm.PackageManager.DONT_KILL_APP
                )
                pm.setComponentEnabledSetting(
                    cn,
                    android.content.pm.PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                    android.content.pm.PackageManager.DONT_KILL_APP
                )
                Log.i(TAG, "⚡ [BankNotifListener] Component toggled to force OS re-binding.")
                true
            } catch (e: Exception) {
                Log.e(TAG, "❌ [BankNotifListener] Failed to rebind service", e)
                false
            }
        }

        @Synchronized
        fun getPendingNotifications(context: Context): List<Map<String, Any>> {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val jsonString = prefs.getString(KEY_PENDING_NOTIFS, null) ?: return emptyList()
            val list = mutableListOf<Map<String, Any>>()
            try {
                val array = JSONArray(jsonString)
                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    val map = mutableMapOf<String, Any>()
                    map["id"] = obj.optString("id")
                    map["packageName"] = obj.optString("packageName")
                    map["title"] = obj.optString("title")
                    map["text"] = obj.optString("text")
                    map["subText"] = obj.optString("subText")
                    map["postTime"] = obj.optLong("postTime")
                    list.add(map)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error reading pending notifications", e)
            }
            return list
        }

        @Synchronized
        fun clearPendingNotifications(context: Context) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().remove(KEY_PENDING_NOTIFS).apply()
        }

        @Synchronized
        fun isDuplicateRecent(key: String, now: Long): Boolean {
            val lastTime = recentNotifCache[key]
            if (lastTime != null && (now - lastTime) < DEBOUNCE_WINDOW_MS) {
                return true
            }
            recentNotifCache[key] = now
            return false
        }

        @Synchronized
        private fun saveToBuffer(context: Context, notifMap: Map<String, Any>) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val jsonString = prefs.getString(KEY_PENDING_NOTIFS, "[]")
            try {
                val array = JSONArray(jsonString)
                val newId = notifMap["id"] as? String ?: ""
                val newPkg = notifMap["packageName"] as? String ?: ""
                val newTitle = notifMap["title"] as? String ?: ""
                val newText = notifMap["text"] as? String ?: ""

                // Prevent duplicates in buffer
                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    if (obj.optString("id") == newId ||
                        (obj.optString("packageName") == newPkg &&
                         obj.optString("title") == newTitle &&
                         obj.optString("text") == newText)) {
                        Log.d(TAG, "⏭️ [BankNotifListener] Duplicate in buffer, skipping saveToBuffer.")
                        return
                    }
                }

                val newObj = JSONObject()
                newObj.put("id", notifMap["id"])
                newObj.put("packageName", notifMap["packageName"])
                newObj.put("title", notifMap["title"])
                newObj.put("text", notifMap["text"])
                newObj.put("subText", notifMap["subText"])
                newObj.put("postTime", notifMap["postTime"])

                // Append new notification
                array.put(newObj)

                // Limit buffer size to prevent memory leaks
                val trimmedArray = JSONArray()
                val startIdx = if (array.length() > MAX_BUFFER_SIZE) array.length() - MAX_BUFFER_SIZE else 0
                for (i in startIdx until array.length()) {
                    trimmedArray.put(array.get(i))
                }

                prefs.edit().putString(KEY_PENDING_NOTIFS, trimmedArray.toString()).apply()
            } catch (e: Exception) {
                Log.e(TAG, "Error buffering notification", e)
            }
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        isServiceConnected = true
        Log.i(TAG, "🟢 [BankNotifListener] Notification Listener Service CONNECTED and ACTIVE!")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        isServiceConnected = false
        Log.w(TAG, "🔴 [BankNotifListener] Notification Listener Service DISCONNECTED!")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        val packageName = sbn.packageName ?: return

        val extras = sbn.notification?.extras

        val title = extras?.getCharSequence(Notification.EXTRA_TITLE)?.toString()?.trim()
            ?: extras?.getCharSequence(Notification.EXTRA_TITLE_BIG)?.toString()?.trim()
            ?: ""

        // Extract bigText, regularText, or multi-line textLines
        val bigText = extras?.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()?.trim() ?: ""
        val regularText = extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString()?.trim() ?: ""
        val subText = extras?.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString()?.trim() ?: ""
        val summaryText = extras?.getCharSequence(Notification.EXTRA_SUMMARY_TEXT)?.toString()?.trim() ?: ""

        val textLines = extras?.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
            ?.joinToString(" ") { it.toString().trim() } ?: ""

        val text = when {
            bigText.isNotEmpty() -> bigText
            regularText.isNotEmpty() -> regularText
            textLines.isNotEmpty() -> textLines
            summaryText.isNotEmpty() -> summaryText
            else -> ""
        }

        // Check if notification is from an SMS messaging app containing financial keywords
        val isSmsApp = packageName.contains("messaging", ignoreCase = true) ||
            packageName.contains(".mms", ignoreCase = true) ||
            packageName.contains("sms", ignoreCase = true)

        val isSmsBank = isSmsApp && (
            title.contains("kbank", ignoreCase = true) ||
            title.contains("k plus", ignoreCase = true) ||
            title.contains("scb", ignoreCase = true) ||
            title.contains("ktb", ignoreCase = true) ||
            title.contains("ttb", ignoreCase = true) ||
            title.contains("bbl", ignoreCase = true) ||
            title.contains("krungsri", ignoreCase = true) ||
            title.contains("bay", ignoreCase = true) ||
            title.contains("gsb", ignoreCase = true) ||
            title.contains("uob", ignoreCase = true) ||
            title.contains("cimb", ignoreCase = true) ||
            title.contains("truemoney", ignoreCase = true) ||
            text.contains("บช.", ignoreCase = true) ||
            text.contains("บัญชี", ignoreCase = true) ||
            text.contains("เงินเข้า", ignoreCase = true) ||
            text.contains("เงินออก", ignoreCase = true) ||
            text.contains("ใช้จ่าย", ignoreCase = true) ||
            text.contains("ยอดคงเหลือ", ignoreCase = true) ||
            text.contains("บาท", ignoreCase = true)
        )

        // Filter: check if package belongs to supported Thai banking, e-wallet, SMS, or ADB test package
        val isSupported = isSmsBank ||
            SUPPORTED_PACKAGES.contains(packageName) ||
            packageName.contains("kasikorn", ignoreCase = true) ||
            packageName.contains("kplus", ignoreCase = true) ||
            packageName.contains("scb", ignoreCase = true) ||
            packageName.contains("ktb", ignoreCase = true) ||
            packageName.contains("truemoney", ignoreCase = true) ||
            packageName.contains("ttb", ignoreCase = true) ||
            packageName.contains("krungsri", ignoreCase = true) ||
            packageName.contains("bbl", ignoreCase = true) ||
            packageName.contains("mymo", ignoreCase = true) ||
            packageName.contains("dime", ignoreCase = true) ||
            packageName.contains("shell", ignoreCase = true)

        // 📝 [ALL DEVICE NOTIFICATIONS LOG] Detailed log for inspection and debugging
        Log.i(
            TAG,
            "🔔 [DEVICE_NOTIF] pkg='$packageName' | isBank=$isSupported | title='$title' | text='$text' | subText='$subText'"
        )

        if (!isSupported) {
            return
        }

        if (title.isEmpty() && text.isEmpty()) {
            Log.d(TAG, "⚠️ [BankNotifListener] Empty title and text from $packageName, skipping.")
            return
        }

        // Debounce multi-firing of the exact same notification from Android OS within 4s
        val dedupeKey = "${packageName}|${title}|${text}"
        val now = System.currentTimeMillis()
        if (isDuplicateRecent(dedupeKey, now)) {
            Log.i(TAG, "⏭️ [BankNotifListener] Ignored duplicate rapid notification: pkg=$packageName | title='$title'")
            return
        }

        val notifMap = mapOf(
            "id" to "${packageName}_${sbn.postTime}_${sbn.id}",
            "packageName" to packageName,
            "title" to title,
            "text" to text,
            "subText" to subText,
            "postTime" to sbn.postTime
        )

        Log.i(TAG, "🎯 [BankNotifListener] MATCHED: pkg=$packageName | title='$title' | text='$text' | subText='$subText'")

        // Save to buffer for background resilience
        saveToBuffer(applicationContext, notifMap)
        Log.d(TAG, "💾 [BankNotifListener] Saved to native buffer. Active EventSink: ${eventSink != null}")

        // If Flutter UI is alive, stream to Dart directly on Main Thread
        eventSink?.let { sink ->
            android.os.Handler(android.os.Looper.getMainLooper()).post {
                try {
                    sink.success(notifMap)
                    Log.i(TAG, "🚀 [BankNotifListener] Successfully streamed notification to Flutter Dart runtime!")
                } catch (e: Exception) {
                    Log.e(TAG, "❌ [BankNotifListener] Error streaming to Flutter sink", e)
                }
            }
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        // No-op
    }
}
