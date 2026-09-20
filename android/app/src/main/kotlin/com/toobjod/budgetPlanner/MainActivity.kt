package com.toobjod.budgetPlanner

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.util.Log
import androidx.annotation.NonNull
import com.toobjod.budgetPlanner.notification.BankNotificationListenerService
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.toobjod.budgetPlanner/notification_channel"
    private val EVENT_CHANNEL = "com.toobjod.budgetPlanner/notification_stream"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // MethodChannel for permission check, opening settings, and buffer management
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isPermissionGranted" -> {
                    val enabled = isNotificationServiceEnabled()
                    if (enabled) {
                        tryRebindNotificationListener()
                    }
                    result.success(enabled)
                }
                "isServiceConnected" -> {
                    result.success(BankNotificationListenerService.isServiceConnected && BankNotificationListenerService.instance != null)
                }
                "rebindService" -> {
                    val success = BankNotificationListenerService.rebindService(applicationContext, forceToggle = true)
                    result.success(success)
                }
                "isBatteryOptimizationIgnored" -> {
                    result.success(isBatteryOptimizationIgnored())
                }
                "requestIgnoreBatteryOptimization" -> {
                    requestIgnoreBatteryOptimization()
                    result.success(true)
                }
                "openNotificationSettings" -> {
                    openNotificationSettings()
                    result.success(true)
                }
                "openAppDetailsSettings" -> {
                    openAppDetailsSettings()
                    result.success(true)
                }
                "getPendingNotifications" -> {
                    val list = BankNotificationListenerService.getPendingNotifications(applicationContext)
                    result.success(list)
                }
                "syncMissedNotifications" -> {
                    if (!BankNotificationListenerService.isServiceConnected || BankNotificationListenerService.instance == null) {
                        BankNotificationListenerService.rebindService(applicationContext, forceToggle = false)
                    }
                    val list = BankNotificationListenerService.fetchActiveAndPendingNotifications(applicationContext)
                    result.success(list)
                }
                "clearPendingNotifications" -> {
                    BankNotificationListenerService.clearPendingNotifications(applicationContext)
                    result.success(true)
                }
                "sendTestNotification" -> {
                    val pkg = call.argument<String>("packageName") ?: "com.kasikorn.retail.mbanking.wap"
                    val title = call.argument<String>("title") ?: "K PLUS"
                    val text = call.argument<String>("text") ?: "เงินเข้า 500.00 บ. โอนจาก x-9999"
                    
                    val notifMap = mapOf(
                        "id" to "test_${System.currentTimeMillis()}",
                        "packageName" to pkg,
                        "title" to title,
                        "text" to text,
                        "subText" to "ทดสอบจำลองแจ้งเตือน",
                        "postTime" to System.currentTimeMillis()
                    )

                    // Stream to Dart directly
                    BankNotificationListenerService.eventSink?.let { sink ->
                        android.os.Handler(android.os.Looper.getMainLooper()).post {
                            sink.success(notifMap)
                        }
                    }
                    result.success(true)
                }
                "shareText" -> {
                    val text = call.argument<String>("text") ?: ""
                    val subject = call.argument<String>("subject") ?: "รายงานการเงิน - เจ้าตูบจด"
                    val sendIntent = Intent().apply {
                        action = Intent.ACTION_SEND
                        putExtra(Intent.EXTRA_TEXT, text)
                        putExtra(Intent.EXTRA_SUBJECT, subject)
                        type = "text/plain"
                    }
                    val shareIntent = Intent.createChooser(sendIntent, "แชร์รายงานการเงิน")
                    startActivity(shareIntent)
                    result.success(true)
                }
                "shareCsv" -> {
                    try {
                        val csvContent = call.argument<String>("csvContent") ?: ""
                        val fileName = call.argument<String>("fileName") ?: "financial_report.csv"
                        val reportFile = java.io.File(cacheDir, fileName)
                        reportFile.writeBytes(csvContent.toByteArray(java.nio.charset.StandardCharsets.UTF_8))

                        val uri: Uri = androidx.core.content.FileProvider.getUriForFile(
                            this,
                            "${applicationContext.packageName}.fileprovider",
                            reportFile
                        )
                        val sendIntent = Intent().apply {
                            action = Intent.ACTION_SEND
                            putExtra(Intent.EXTRA_STREAM, uri)
                            putExtra(Intent.EXTRA_SUBJECT, "รายงานการเงิน (CSV) - เจ้าตูบจด")
                            type = "text/comma-separated-values"
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                        }
                        val shareIntent = Intent.createChooser(sendIntent, "ส่งออกรายงานการเงิน (CSV)")
                        startActivity(shareIntent)
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Error sharing CSV", e)
                        result.error("SHARE_ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // EventChannel for real-time notification streaming
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    BankNotificationListenerService.eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    BankNotificationListenerService.eventSink = null
                }
            }
        )
    }

    private fun isNotificationServiceEnabled(): Boolean {
        val pkgName = packageName
        val flat = Settings.Secure.getString(contentResolver, "enabled_notification_listeners")
        if (flat != null && flat.isNotEmpty()) {
            val names = flat.split(":").toTypedArray()
            for (name in names) {
                val cn = ComponentName.unflattenFromString(name)
                if (cn != null && cn.packageName == pkgName) {
                    return true
                }
            }
        }
        return false
    }

    private fun isBatteryOptimizationIgnored(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = getSystemService(Context.POWER_SERVICE) as? PowerManager
            return pm?.isIgnoringBatteryOptimizations(packageName) ?: false
        }
        return true
    }

    private fun requestIgnoreBatteryOptimization() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                if (!isBatteryOptimizationIgnored()) {
                    val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                        data = Uri.parse("package:$packageName")
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(intent)
                    return
                }
            } catch (_: Exception) {
                // Fallback to battery optimization settings list
                try {
                    val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(intent)
                    return
                } catch (_: Exception) {}
            }
        }
        openAppDetailsSettings()
    }

    private fun openNotificationSettings() {
        try {
            // Android 11+ (API 30+) direct to component detail settings
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                try {
                    val cn = ComponentName(packageName, BankNotificationListenerService::class.java.name)
                    val detailIntent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_DETAIL_SETTINGS).apply {
                        putExtra(Settings.EXTRA_NOTIFICATION_LISTENER_COMPONENT_NAME, cn.flattenToString())
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(detailIntent)
                    return
                } catch (_: Exception) {}
            }

            // Fallback to standard Notification Listener Settings page
            val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        } catch (e: Exception) {
            openAppDetailsSettings()
        }
    }

    private fun openAppDetailsSettings() {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        } catch (e: Exception) {
            val fallbackIntent = Intent(Settings.ACTION_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(fallbackIntent)
        }
    }

    override fun onResume() {
        super.onResume()
        if (isNotificationServiceEnabled()) {
            tryRebindNotificationListener()
        }
    }

    private fun tryRebindNotificationListener() {
        if (!BankNotificationListenerService.isServiceConnected || BankNotificationListenerService.instance == null) {
            BankNotificationListenerService.rebindService(this, forceToggle = true)
        }
    }
}
