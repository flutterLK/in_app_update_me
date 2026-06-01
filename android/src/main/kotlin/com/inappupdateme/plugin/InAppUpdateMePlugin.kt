package com.inappupdateme.plugin

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.content.FileProvider
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.InstallStatus
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.*
import okhttp3.*
import org.json.JSONObject
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

class InAppUpdateMePlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
  private lateinit var channel: MethodChannel
  private lateinit var context: Context
  private var activity: Activity? = null
  private var appUpdateManager: AppUpdateManager? = null
  private val updateRequestCode = 100
  private var pendingResult: Result? = null
  private val pluginScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

  private val installStateUpdatedListener = InstallStateUpdatedListener { state ->
    when (state.installStatus()) {
      InstallStatus.DOWNLOADED -> {
        channel.invokeMethod("onUpdateDownloaded", null)
      }
      InstallStatus.INSTALLED -> {
        channel.invokeMethod("onUpdateInstalled", null)
      }
      InstallStatus.FAILED -> {
        channel.invokeMethod("onUpdateFailed", mapOf(
          "error" to (state.installErrorCode().toString())
        ))
      }
      InstallStatus.DOWNLOADING -> {
        val bytesDownloaded = state.bytesDownloaded()
        val totalBytesToDownload = state.totalBytesToDownload()
        if (totalBytesToDownload > 0) {
          val progress = ((bytesDownloaded * 100) / totalBytesToDownload).toInt()
          channel.invokeMethod("onUpdateProgress", mapOf(
            "progress" to progress,
            "bytesDownloaded" to bytesDownloaded,
            "totalBytes" to totalBytesToDownload,
            "state" to "downloading"
          ))
        }
      }
    }
  }

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(binding.binaryMessenger, "in_app_update_me")
    channel.setMethodCallHandler(this)
    context = binding.applicationContext
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
    when (call.method) {
      "checkForUpdate" -> {
        val usePlayStore = call.argument<Boolean>("usePlayStore") ?: true
        val useAppStore = call.argument<Boolean>("useAppStore") ?: true
        val updateUrl = call.argument<String>("updateUrl")
        val currentVersion = call.argument<String>("currentVersion")
        checkForUpdate(usePlayStore || useAppStore, updateUrl, currentVersion, result)
      }
      "startFlexibleUpdate" -> {
        val downloadUrl = call.argument<String>("downloadUrl")
        startFlexibleUpdate(result, downloadUrl)
      }
      "startImmediateUpdate" -> {
        startImmediateUpdate(result)
      }
      "completeFlexibleUpdate" -> {
        completeFlexibleUpdate(result)
      }
      "downloadAndInstallApk" -> {
        val downloadUrl = call.argument<String>("downloadUrl")
        if (downloadUrl != null) {
          downloadAndInstallApk(downloadUrl, result)
        } else {
          result.error("INVALID_ARGS", "Download URL is required", null)
        }
      }
      "isUpdateAvailable" -> {
        isUpdateAvailable(result)
      }
      "getPlatformVersion" -> {
        result.success("Android ${Build.VERSION.RELEASE}")
      }
      else -> {
        result.notImplemented()
      }
    }
  }

  private fun checkForUpdate(usePlayStore: Boolean, updateUrl: String?, currentVersion: String?, result: Result) {
    if (usePlayStore) {
      checkPlayStoreUpdate(result)
    } else if (updateUrl != null) {
      checkDirectUpdate(updateUrl, currentVersion, result)
    } else {
      result.error("INVALID_ARGS", "Either usePlayStore must be true or updateUrl must be provided", null)
    }
  }

  private fun checkPlayStoreUpdate(result: Result) {
    if (activity == null) {
      result.error("NO_ACTIVITY", "Activity is not available", null)
      return
    }

    appUpdateManager = AppUpdateManagerFactory.create(context)
    appUpdateManager?.registerListener(installStateUpdatedListener)

    appUpdateManager?.appUpdateInfo?.addOnSuccessListener { appUpdateInfo ->
      val updateAvailable = appUpdateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE
      val immediateAllowed = appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)
      val flexibleAllowed = appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)

      val resultMap = HashMap<String, Any>()
      resultMap["updateAvailable"] = updateAvailable
      resultMap["immediateUpdateAllowed"] = immediateAllowed
      resultMap["flexibleUpdateAllowed"] = flexibleAllowed

      if (updateAvailable) {
        resultMap["availableVersionCode"] = appUpdateInfo.availableVersionCode()
        resultMap["updatePriority"] = appUpdateInfo.updatePriority()
      }

      result.success(resultMap)
    }?.addOnFailureListener { exception ->
      result.error("CHECK_FAILED", exception.message, null)
    }
  }

  // Fix #4: Parse the JSON response from the server
  private fun checkDirectUpdate(updateUrl: String, currentVersion: String?, result: Result) {
    val client = OkHttpClient()
    val request = Request.Builder()
      .url(updateUrl)
      .build()

    pluginScope.launch(Dispatchers.IO) {
      try {
        val response = client.newCall(request).execute()
        if (response.isSuccessful) {
          val body = response.body?.string()
          if (body != null) {
            val jsonResponse = JSONObject(body)
            val resultMap = HashMap<String, Any>()
            resultMap["updateAvailable"] = jsonResponse.optBoolean("updateAvailable", true)
            resultMap["immediateUpdateAllowed"] = jsonResponse.optBoolean("immediateUpdateAllowed", false)
            resultMap["flexibleUpdateAllowed"] = jsonResponse.optBoolean("flexibleUpdateAllowed", true)
            resultMap["directUpdate"] = true
            resultMap["downloadUrl"] = jsonResponse.optString("downloadUrl", updateUrl)

            if (jsonResponse.has("version")) {
              resultMap["appStoreVersion"] = jsonResponse.getString("version")
            }
            if (jsonResponse.has("releaseNotes")) {
              resultMap["releaseNotes"] = jsonResponse.getString("releaseNotes")
            }
            if (jsonResponse.has("priority")) {
              resultMap["updatePriority"] = jsonResponse.getInt("priority")
            }
            if (jsonResponse.has("forceUpdate")) {
              resultMap["forceUpdate"] = jsonResponse.getBoolean("forceUpdate")
            }
            if (currentVersion != null) {
              resultMap["currentVersion"] = currentVersion
            }

            withContext(Dispatchers.Main) {
              result.success(resultMap)
            }
          } else {
            withContext(Dispatchers.Main) {
              result.error("EMPTY_RESPONSE", "Server returned empty response", null)
            }
          }
        } else {
          withContext(Dispatchers.Main) {
            result.error("HTTP_ERROR", "Server returned ${response.code}", null)
          }
        }
      } catch (e: IOException) {
        withContext(Dispatchers.Main) {
          result.error("NETWORK_ERROR", e.message, null)
        }
      }
    }
  }

  private fun startFlexibleUpdate(result: Result, downloadUrl: String?) {
    if (activity == null) {
      result.error("NO_ACTIVITY", "Activity is not available", null)
      return
    }

    if (downloadUrl != null) {
      downloadAndInstallApk(downloadUrl, result)
      return
    }

    appUpdateManager?.appUpdateInfo?.addOnSuccessListener { appUpdateInfo ->
      if (appUpdateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE &&
          appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)) {
        try {
          activity?.let { act ->
            appUpdateManager?.startUpdateFlowForResult(
              appUpdateInfo,
              act,
              AppUpdateOptions.newBuilder(AppUpdateType.FLEXIBLE).build(),
              updateRequestCode
            )
            result.success(true)
          } ?: result.error("NO_ACTIVITY", "Activity is not available", null)
        } catch (e: Exception) {
          result.error("UPDATE_FAILED", e.message, null)
        }
      } else {
        result.success(false)
      }
    }?.addOnFailureListener { exception ->
      result.error("CHECK_FAILED", exception.message, null)
    }
  }

  private fun startImmediateUpdate(result: Result) {
    if (activity == null) {
      result.error("NO_ACTIVITY", "Activity is not available", null)
      return
    }

    appUpdateManager?.appUpdateInfo?.addOnSuccessListener { appUpdateInfo ->
      if (appUpdateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE &&
          appUpdateInfo.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)) {
        try {
          activity?.let { act ->
            appUpdateManager?.startUpdateFlowForResult(
              appUpdateInfo,
              act,
              AppUpdateOptions.newBuilder(AppUpdateType.IMMEDIATE).build(),
              updateRequestCode
            )
            result.success(true)
          } ?: result.error("NO_ACTIVITY", "Activity is not available", null)
        } catch (e: Exception) {
          result.error("UPDATE_FAILED", e.message, null)
        }
      } else {
        result.success(false)
      }
    }?.addOnFailureListener { exception ->
      result.error("CHECK_FAILED", exception.message, null)
    }
  }

  private fun completeFlexibleUpdate(result: Result) {
    appUpdateManager?.completeUpdate()?.addOnSuccessListener {
      result.success(true)
    }?.addOnFailureListener { exception ->
      result.error("COMPLETE_FAILED", exception.message, null)
    } ?: result.error("NO_MANAGER", "AppUpdateManager not initialized", null)
  }

  private fun downloadAndInstallApk(downloadUrl: String, result: Result) {
    val client = OkHttpClient()
    val request = Request.Builder()
      .url(downloadUrl)
      .build()

    pluginScope.launch(Dispatchers.IO) {
      try {
        val response = client.newCall(request).execute()
        if (response.isSuccessful) {
          val file = File(context.getExternalFilesDir(null), "update.apk")

          // Fix #9: Use Kotlin's use { } to ensure stream is closed
          response.body?.byteStream()?.use { inputStream ->
            FileOutputStream(file).use { outputStream ->
              val totalBytes = response.body?.contentLength() ?: -1
              var downloadedBytes = 0L
              val buffer = ByteArray(8192)
              var bytesRead: Int

              while (inputStream.read(buffer).also { bytesRead = it } != -1) {
                outputStream.write(buffer, 0, bytesRead)
                downloadedBytes += bytesRead

                if (totalBytes > 0) {
                  val progress = ((downloadedBytes * 100) / totalBytes).toInt()
                  withContext(Dispatchers.Main) {
                    channel.invokeMethod("onUpdateProgress", mapOf(
                      "progress" to progress,
                      "bytesDownloaded" to downloadedBytes,
                      "totalBytes" to totalBytes,
                      "state" to "downloading"
                    ))
                  }
                }
              }
            }
          }

          withContext(Dispatchers.Main) {
            channel.invokeMethod("onUpdateDownloaded", null)
            installApk(file)
            result.success(true)
          }
        } else {
          withContext(Dispatchers.Main) {
            result.error("DOWNLOAD_FAILED", "Server returned ${response.code}", null)
          }
        }
      } catch (e: IOException) {
        withContext(Dispatchers.Main) {
          result.error("DOWNLOAD_FAILED", e.message, null)
        }
      }
    }
  }

  private fun installApk(file: File) {
    val intent = Intent(Intent.ACTION_VIEW)
    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
      val uri = FileProvider.getUriForFile(
        context,
        "${context.packageName}.fileprovider",
        file
      )
      intent.setDataAndType(uri, "application/vnd.android.package-archive")
      intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
    } else {
      intent.setDataAndType(
        Uri.fromFile(file),
        "application/vnd.android.package-archive"
      )
    }

    activity?.startActivity(intent)
  }

  private fun isUpdateAvailable(result: Result) {
    appUpdateManager?.appUpdateInfo?.addOnSuccessListener { appUpdateInfo ->
      val updateAvailable = appUpdateInfo.updateAvailability() == UpdateAvailability.UPDATE_AVAILABLE
      result.success(updateAvailable)
    }?.addOnFailureListener { exception ->
      result.error("CHECK_FAILED", exception.message, null)
    }
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    if (requestCode == updateRequestCode) {
      when (resultCode) {
        Activity.RESULT_OK -> {
          channel.invokeMethod("onUpdateResult", mapOf("result" to "success"))
        }
        Activity.RESULT_CANCELED -> {
          channel.invokeMethod("onUpdateResult", mapOf("result" to "cancelled"))
        }
        else -> {
          channel.invokeMethod("onUpdateResult", mapOf("result" to "failed"))
        }
      }
      return true
    }
    return false
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    pluginScope.cancel()
    appUpdateManager?.unregisterListener(installStateUpdatedListener)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivity() {
    activity = null
  }
}
