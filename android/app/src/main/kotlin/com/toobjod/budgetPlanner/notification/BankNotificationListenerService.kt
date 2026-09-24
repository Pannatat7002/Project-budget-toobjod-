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
        var instance: BankNotificationListenerService? = null

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
            "com.kasikornbank.makebykbank",     // MAKE by KBank (Official)
            "com.kasikornbank.make",            // MAKE by KBank (Alias)
            "com.kbank.make",                   // MAKE by KBank (Alias)
            "com.scb.phone",                    // SCB EASY (Official)
            "com.scb.easy",                     // SCB EASY (Alias)
            "ktbcs.netbank",                    // Krungthai NEXT (Official)
            "ktb.cs.mobile.app",                // Krungthai NEXT (Alias)
            "com.ktb.customer.qr",              // Paotang / G-Wallet (Official)
            "com.bbl.mBanking",                 // Bangkok Bank (Official)
            "com.bbl.mobilebanking",            // Bangkok Bank (New Package)
            "com.bbl.mobilephone",              // Bangkok Bank (Alias)
            "com.TMBTOUCH.PRODUCTION",          // ttb touch (Official)
            "com.ttbbank.oneapp",               // ttb touch (Alias)
            "com.tmb.mbanking",                 // ttb touch (Alias)
            "com.krungsri.kma",                 // KMA Krungsri (Official)
            "com.bay.mbanking",                 // KMA Krungsri (Alias)
            "th.co.truemoney.wallet",           // TrueMoney (Official)
            "com.shopeepay.th",                 // ShopeePay (Official)
            "com.airpay",                       // ShopeePay (Alias)
            "com.gsb.mymo",                     // MyMo GSB (Official)
            "com.my.mymo",                      // MyMo GSB (Alias)
            "co.th.dime",                       // Dime! by KKP
            "com.dimekkp.dimeapp",              // Dime! (Official)
            "com.krungsri.kept",                // Kept by Krungsri
            "com.cimbthai.digital",             // CIMB THAI
            "com.uob.mightyth",                 // UOB TMRW
            "com.google.android.apps.messaging", // Google Messages (SMS)
            "com.samsung.android.messaging",     // Samsung Messages (SMS)
            "com.android.mms",                   // Android MMS/SMS
            "com.android.shell"                 // ADB Shell command testing
        )

        /**
         * Safe Rebind Mechanism:
         * 1. Uses requestRebind on Android 7+ (API 24+)
         * 2. Only performs component toggle if explicitly requested with forceToggle = true.
         *    Regular routine checks MUST NOT toggle component state as it causes Android 11+
         *    to kill/drop the service permanently.
         */
        @Synchronized
        fun rebindService(context: Context, forceToggle: Boolean = false): Boolean {
            if (isServiceConnected && instance != null && !forceToggle) {
                return true
            }
            return try {
                val cn = ComponentName(context, BankNotificationListenerService::class.java)
                
                if (forceToggle) {
                    // Only toggle component state when explicitly forced (e.g. manual user recovery)
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
                    Log.i(TAG, "⚡ [BankNotifListener] Component toggled for forced recovery.")
                }

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    NotificationListenerService.requestRebind(cn)
                    Log.i(TAG, "🔄 [BankNotifListener] requestRebind called successfully.")
                }
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
            recentNotifCache.clear()
            Log.i(TAG, "🧹 [BankNotifListener] Cleared native pending buffer and debounce cache.")
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
        @Synchronized
        fun fetchActiveAndPendingNotifications(context: Context): List<Map<String, Any>> {
            val combined = mutableListOf<Map<String, Any>>()
            val seenKeys = mutableSetOf<String>()

            // 1. First, retrieve any notifications previously stored in the SharedPreferences buffer
            val pending = getPendingNotifications(context)
            for (item in pending) {
                val pkg = item["packageName"] as? String ?: ""
                val title = item["title"] as? String ?: ""
                val text = item["text"] as? String ?: ""
                val postTime = item["postTime"] ?: 0L
                val key = "$pkg|$title|$text|$postTime"
                if (seenKeys.add(key)) {
                    combined.add(item)
                }
            }

            // 2. Query active notifications currently posted in Android status bar tray
            val currentInstance = instance
            if (currentInstance != null) {
                try {
                    val activeSbns = currentInstance.activeNotifications
                    if (activeSbns != null) {
                        Log.i(TAG, "🔍 [BankNotifListener] Scanning ${activeSbns.size} active notifications in status bar...")
                        for (sbn in activeSbns) {
                            val data = extractNotificationData(sbn)
                            if (data != null) {
                                val pkg = data["packageName"] as? String ?: ""
                                val title = data["title"] as? String ?: ""
                                val text = data["text"] as? String ?: ""
                                val postTime = data["postTime"] ?: 0L
                                val key = "$pkg|$title|$text|$postTime"
                                if (seenKeys.add(key)) {
                                    combined.add(data)
                                    Log.i(TAG, "📥 [BankNotifListener] Found active bank notification in status bar: pkg=$pkg, title='$title'")
                                }
                            }
                        }
                    }
                } catch (e: Exception) {
                    Log.e(TAG, "❌ [BankNotifListener] Error querying activeNotifications", e)
                }
            } else {
                Log.w(TAG, "⚠️ [BankNotifListener] Service instance is not connected. Rebind might be needed.")
            }

            // 3. Clear buffer on native side now that we collected them
            clearPendingNotifications(context)
            Log.i(TAG, "✅ [BankNotifListener] Total ${combined.size} notification(s) prepared for Flutter.")
            return combined
        }

        @JvmStatic
        fun extractNotificationData(sbn: StatusBarNotification?): Map<String, Any>? {
            if (sbn == null) return null
            val packageName = sbn.packageName ?: return null

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
                return null
            }

            if (title.isEmpty() && text.isEmpty()) {
                Log.d(TAG, "⚠️ [BankNotifListener] Empty title and text from $packageName, skipping.")
                return null
            }

            return mapOf(
                "id" to "${packageName}_${sbn.postTime}_${sbn.id}",
                "packageName" to packageName,
                "title" to title,
                "text" to text,
                "subText" to subText,
                "postTime" to sbn.postTime
            )
        }
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        instance = this
        isServiceConnected = true
        Log.i(TAG, "🟢 [BankNotifListener] Notification Listener Service CONNECTED and ACTIVE!")
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        instance = null
        isServiceConnected = false
        Log.w(TAG, "🔴 [BankNotifListener] Notification Listener Service DISCONNECTED!")
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        isServiceConnected = false
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        val notifMap = extractNotificationData(sbn) ?: return

        // Debounce multi-firing of the exact same notification from Android OS within 4s
        val dedupeKey = "${notifMap["packageName"]}|${notifMap["title"]}|${notifMap["text"]}"
        val now = System.currentTimeMillis()
        if (isDuplicateRecent(dedupeKey, now)) {
            Log.i(TAG, "⏭️ [BankNotifListener] Ignored duplicate rapid notification: pkg=${notifMap["packageName"]} | title='${notifMap["title"]}'")
            return
        }

        Log.i(TAG, "🎯 [BankNotifListener] MATCHED: pkg=${notifMap["packageName"]} | title='${notifMap["title"]}' | text='${notifMap["text"]}' | subText='${notifMap["subText"]}'")

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
