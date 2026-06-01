import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../in_app_update_me_platform_interface.dart';
import 'models/update_info.dart';
import 'models/update_config.dart';
import 'listeners/update_listener.dart';

class InAppUpdateMe {
  static final InAppUpdateMe _instance = InAppUpdateMe._internal();
  factory InAppUpdateMe() => _instance;
  InAppUpdateMe._internal();

  InAppUpdateMePlatform get _platform => InAppUpdateMePlatform.instance;
  DefaultUpdateListener? _updateListener;

  // Fix #5: Store the config
  UpdateConfig? _config;

  /// Initialize the plugin with configuration
  void initialize(UpdateConfig config) {
    _config = config;
    _updateListener = DefaultUpdateListener();
    _platform.setUpdateListener(_updateListener!);
  }

  /// Get the current configuration
  UpdateConfig? get config => _config;

  /// Get platform version for debugging
  Future<String?> getPlatformVersion() {
    return _platform.getPlatformVersion();
  }

  /// Check for available updates
  ///
  /// [useStore]: Whether to check Play Store/App Store (default: true)
  /// [updateUrl]: URL to check for direct updates (required if useStore is false)
  /// [currentVersion]: Current app version (optional, auto-detected if not provided)
  Future<AppUpdateInfo?> checkForUpdate({
    bool useStore = true,
    String? updateUrl,
    String? currentVersion,
  }) async {
    try {
      if (currentVersion == null) {
        final packageInfo = await PackageInfo.fromPlatform();
        currentVersion = packageInfo.version;
      }

      final updateInfo = await _platform.checkForUpdate(
        useStore: useStore,
        updateUrl: updateUrl,
        currentVersion: currentVersion,
      );

      if (updateInfo != null) {
        return AppUpdateInfo.fromPlatformUpdateInfo(updateInfo);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking for update: $e');
      }
      return null;
    }
  }

  /// Start a flexible update
  Future<bool> startFlexibleUpdate({String? downloadUrl}) async {
    try {
      return await _platform.startFlexibleUpdate(downloadUrl: downloadUrl);
    } catch (e) {
      if (kDebugMode) {
        print('Error starting flexible update: $e');
      }
      return false;
    }
  }

  /// Start an immediate update (Android only, iOS will redirect to App Store)
  Future<bool> startImmediateUpdate() async {
    try {
      return await _platform.startImmediateUpdate();
    } catch (e) {
      if (kDebugMode) {
        print('Error starting immediate update: $e');
      }
      return false;
    }
  }

  /// Complete a flexible update (Android only)
  Future<bool> completeFlexibleUpdate() async {
    try {
      return await _platform.completeFlexibleUpdate();
    } catch (e) {
      if (kDebugMode) {
        print('Error completing flexible update: $e');
      }
      return false;
    }
  }

  /// Download and install update directly
  Future<bool> downloadAndInstallUpdate(String downloadUrl) async {
    try {
      return await _platform.downloadAndInstallUpdate(downloadUrl);
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading and installing update: $e');
      }
      return false;
    }
  }

  /// Check if an update is available (quick check)
  Future<bool> isUpdateAvailable() async {
    try {
      return await _platform.isUpdateAvailable();
    } catch (e) {
      if (kDebugMode) {
        print('Error checking update availability: $e');
      }
      return false;
    }
  }

  /// Open App Store/Play Store for manual update
  // Fix #7: Use iTunes lookup API for iOS instead of hardcoded URL
  Future<bool> openStore() async {
    try {
      String storeUrl;
      if (Platform.isAndroid) {
        final packageInfo = await PackageInfo.fromPlatform();
        storeUrl = 'https://play.google.com/store/apps/details?id=${packageInfo.packageName}';
      } else if (Platform.isIOS) {
        final packageInfo = await PackageInfo.fromPlatform();
        final bundleId = packageInfo.packageName;

        // Look up the App Store URL using iTunes API
        try {
          final lookupUrl = Uri.parse('https://itunes.apple.com/lookup?bundleId=$bundleId');
          final response = await http.get(lookupUrl);
          if (response.statusCode == 200) {
            final json = jsonDecode(response.body);
            final results = json['results'] as List?;
            if (results != null && results.isNotEmpty) {
              final trackId = results[0]['trackId'];
              storeUrl = 'https://apps.apple.com/app/id$trackId';
            } else {
              storeUrl = 'https://apps.apple.com/app/$bundleId';
            }
          } else {
            storeUrl = 'https://apps.apple.com/app/$bundleId';
          }
        } catch (_) {
          storeUrl = 'https://apps.apple.com/app/$bundleId';
        }
      } else {
        return false;
      }

      final uri = Uri.parse(storeUrl);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error opening store: $e');
      }
      return false;
    }
  }

  /// Set update listener for callbacks
  void setUpdateListener(DefaultUpdateListener listener) {
    _updateListener = listener;
    _platform.setUpdateListener(listener);
  }

  /// Get the current update listener
  DefaultUpdateListener? get updateListener => _updateListener;

  /// Remove update listener
  void removeUpdateListener() {
    _updateListener = null;
  }

  /// Convenience method to perform a complete update check and handle force updates
  Future<UpdateResult> performUpdateCheck(UpdateConfig config) async {
    final updateInfo = await checkForUpdate(
      useStore: config.useStore,
      updateUrl: config.updateUrl,
    );

    if (updateInfo == null) {
      return UpdateResult(
        updateAvailable: false,
        success: true,
        message: 'No update available',
      );
    }

    if (!updateInfo.updateAvailable) {
      return UpdateResult(
        updateAvailable: false,
        success: true,
        message: 'App is up to date',
      );
    }

    // Handle force update
    if (config.forceUpdate) {
      if (config.useStore) {
        if (Platform.isAndroid && updateInfo.immediateUpdateAllowed) {
          final success = await startImmediateUpdate();
          return UpdateResult(
            updateAvailable: true,
            success: success,
            message: success ? 'Force update initiated' : 'Failed to start force update',
            isForceUpdate: true,
          );
        } else {
          final success = await openStore();
          return UpdateResult(
            updateAvailable: true,
            success: success,
            message: success ? 'Redirected to store' : 'Failed to open store',
            isForceUpdate: true,
          );
        }
      } else if (updateInfo.downloadUrl != null) {
        final success = await downloadAndInstallUpdate(updateInfo.downloadUrl!);
        return UpdateResult(
          updateAvailable: true,
          success: success,
          message: success ? 'Direct update initiated' : 'Failed to download update',
          isForceUpdate: true,
        );
      }
    }

    return UpdateResult(
      updateAvailable: true,
      success: true,
      message: 'Update available',
      updateInfo: updateInfo,
    );
  }
}

class UpdateResult {
  final bool updateAvailable;
  final bool success;
  final String message;
  final AppUpdateInfo? updateInfo;
  final bool isForceUpdate;

  UpdateResult({
    required this.updateAvailable,
    required this.success,
    required this.message,
    this.updateInfo,
    this.isForceUpdate = false,
  });
}
