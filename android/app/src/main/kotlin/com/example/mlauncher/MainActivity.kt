package com.example.mlauncher

import android.app.Application
import android.app.NotificationManager
import android.app.SearchManager
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Bundle
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode.transparent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.AdaptiveIconDrawable
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.LayerDrawable
import java.io.File
import java.io.FileOutputStream

class MainActivity: FlutterActivity() {

    private val TAG = "MainChannel"
    private val CHANNEL = "main_channel"

    override fun onCreate(savedInstanceState: Bundle?) {
        intent.putExtra("background_mode", transparent.toString())
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            // Request the WRITE_SETTINGS permission for Android 6.0 and higher
            if (!Settings.System.canWrite(applicationContext)) {
                val intent = Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS)
                intent.data = Uri.parse("package:$packageName")
                startActivityForResult(intent, 200)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "expand" -> {
                    NotificationExpander(this).expand()
                    result.success(null)
                }
                "getAppIconPath" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        val appIconPath = getAppIconPath(packageName)
                        result.success(appIconPath)
                    } else {
                        result.error("MISSING_PACKAGE_NAME", "Package name not provided", null)
                    }
                }
                "searchGoogle" -> {
                    val query = call.argument<String>("query")
                    if (query != null) {
                        searchGoogle(query)
                        result.success(null)
                    } else {
                        result.error("MISSING_ARGUMENT", "Query parameter is missing", null)
                    }
                }
                "openApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        openApp(packageName)
                        result.success(null)
                    } else {
                        result.error("MISSING_PACKAGE_NAME", "Package name not provided", null)
                    }
                }
                "openGallery" -> {
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse("content://media/internal/images/media"))
                    startActivity(intent)
                }
                else -> {
                    result.notImplemented()
                    Log.d(TAG, "Error: No method found for ${call.method}!")
                }
            }
        }
    }
    
    private fun getAppIconPath(packageName: String): String? {
        return try {
            val packageManager: PackageManager = packageManager
            val appInfo = packageManager.getApplicationInfo(packageName, 0)
            val appIcon = appInfo.loadIcon(packageManager)

            return when (appIcon) {
                is BitmapDrawable -> saveBitmapToFile(appIcon.bitmap, packageName)
                is AdaptiveIconDrawable -> {
                    val width = appIcon.intrinsicWidth
                    val height = appIcon.intrinsicHeight

                    // Create a bitmap with an alpha channel
                    val resultBitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                    val canvas = Canvas(resultBitmap)

                    // Draw the adaptive icon on the transparent bitmap
                    appIcon.setBounds(0, 0, canvas.width, canvas.height)
                    appIcon.draw(canvas)

                    saveBitmapToFile(resultBitmap, packageName)
                }
                else -> {
                    // Handle other types of drawables as needed
                    null
                }
            }
        } catch (e: PackageManager.NameNotFoundException) {
            e.printStackTrace()
            null
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    private fun saveBitmapToFile(bitmap: Bitmap, packageName: String): String? {
        try {
            val iconFile = File(cacheDir, "icon_" + packageName + ".png")
            FileOutputStream(iconFile).use { out ->
                bitmap.compress(Bitmap.CompressFormat.PNG, 80, out)
            }
            return iconFile.absolutePath
        } catch (e: Exception) {
            e.printStackTrace()
            return null
        }
    }

    private fun searchGoogle(query: String) {
        try {
            val intent = Intent(Intent.ACTION_WEB_SEARCH)
            intent.putExtra(SearchManager.QUERY, query)
            startActivity(intent)
        } catch (e: Exception) {
            // Log an error
        }
    }

    private fun openApp(packageName: String) {
        val packageManager: PackageManager = packageManager

        try {
            val intent: Intent? = packageManager.getLaunchIntentForPackage(packageName)

            if (intent != null) {
                // The app exists, so launch it
                startActivity(intent)
            } else {
                // The app is not installed, open the app page on the Play Store
                val playStoreIntent = Intent(
                    Intent.ACTION_VIEW,
                    Uri.parse("market://details?id=$packageName")
                )
                startActivity(playStoreIntent)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
