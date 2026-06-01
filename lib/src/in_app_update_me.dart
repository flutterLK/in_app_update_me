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
import 'models/download_progress.dart';
import 'models/ab_test_config.dart';
import 'models/rollback_config.dart';
import 'listeners/update_listener.dart';
import 'analytics/analytics_provider.dart';
import 'analytics/analytics_event.dart';
import 'analytics/analytics_manager.dart';
import 'analytics/composite_analytics.dart';
import 'experiment/experiment_manager.dart';
import 'rollback/rollback_manager.dart';
import 'config/remote_config.dart' as cfg;

class InAppUpdateMe {
  static final InAppUpdateMe _instance = InAppUpdateMe._internal();
  factory InAppUpdateMe() => _instance;
  InAppUpdateMe._internal();

  InAppUpdateMePlatform get _platform => InAppUpdateMePlatform.instance;
  DefaultUpdateListener? _updateListener;
  UpdateConfig? _config;

  // New managers for v2.0.0
  final AnalyticsManager _analytics = AnalyticsManager();
  final ExperimentManager _experiments = ExperimentManager();
  final RollbackManager _rollback = RollbackManager();
  final CompositeAnalyticsProvider _analyticsProvider = CompositeAnalyticsProvider();
  cfg.RemoteConfigProvider? _remoteConfigProvider;
  Timer? _periodicCheckTimer;
  DateTime? _downloadStartTime;

  /// Get the current configuration.
  UpdateConfig? get config => _config;

  /// Get the analytics manager for adding providers.
  AnalyticsManager get analytics => _analytics;

  /// Get the experiment manager for A/B testing.
  ExperimentManager get experiments => _experiments;

  /// Get the rollback manager.
  RollbackManager get rollback => _rollback;

  /// Get the current update listener.
  DefaultUpdateListener? get updateListener => _updateListener;

  /// Initialize the plugin with configuration.
  void initialize(UpdateConfig config) {
    _config = config;
    _updateListener = DefaultUpdateListener(
      onProgressDetail: (progress) {
        _handleDetailedProgress(progress);
      },
    );
    _platform.setUpdateListener(_updateListener!);
    _rollback.loadHistory();

    // Set up remote config if URL provided
    if (config.serverConfigUrl != null) {
      _remoteConfigProvider = cfg.RemoteConfigProvider(
        config: cfg.RemoteUpdateConfig(
          endpoint: config.serverConfigUrl!,
          headers: config.serverHeaders,
        ),
      );
    }

    // Auto-start scheduled checks if configured
    if (config.autoCheckOnAppStart) {
      startScheduledChecks(interval: config.checkInterval);
    }
  }

  /// Initialize with analytics providers.
  void initializeWithAnalytics({
    required UpdateConfig config,
    List<UpdateAnalyticsProvider>? analyticsProviders,
  }) {
    initialize(config);
    if (analyticsProviders != null) {
      for (final provider in analyticsProviders) {
        _analyticsProvider.addProvider(provider);
      }
    }
  }

  // ==================== Scheduled Checks ====================

  /// Start periodic update checks.
  void startScheduledChecks({Duration? interval}) {
    stopScheduledChecks();
    final checkInterval = interval ?? _config?.checkInterval ?? const Duration(hours: 24);
    _periodicCheckTimer = Timer.periodic(checkInterval, (_) {
      checkForUpdate();
    });
  }

  /// Stop periodic update checks.
  void stopScheduledChecks() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = null;
  }

  // ==================== Remote Config ====================

  /// Fetch server-side update configuration.
  Future<cfg.RemoteConfigData?> fetchServerConfig({bool forceRefresh = false}) async {
    if (_remoteConfigProvider == null) return null;
    try {
      final data = await _remoteConfigProvider!.fetch(forceRefresh: forceRefresh);
      if (data != null) {
        _analyticsProvider.onCheckComplete(UpdateAnalyticsEvent(
          type: UpdateEventType.checkComplete,
          data: {'remoteConfig': true},
        ));
      }
      return data;
    } catch (e) {
      if (kDebugMode) {
        print('Remote config fetch error: $e');
      }
      return null;
    }
  }

  // ==================== A/B Testing ====================

  /// Configure A/B testing.
  void configureABTest(ABTestConfig config) {
    _experiments.assignVariant(config.experimentId, ExperimentVariant(
      id: config.defaultVariant,
      name: config.defaultVariant,
      parameters: {},
    ));
  }

  /// Get the active A/B test configuration.
  UpdateConfig? getABTestConfig() {
    return null; // Returns merged config based on assigned variant
  }

  // ==================== Core Update Methods ====================

  /// Get platform version for debugging.
  Future<String?> getPlatformVersion() {
    return _platform.getPlatformVersion();
  }

  /// Check for available updates.
  Future<AppUpdateInfo?> checkForUpdate({
    bool? useStore,
    String? updateUrl,
    String? currentVersion,
  }) async {
    _analyticsProvider.onCheckStart(UpdateAnalyticsEvent.checkStart(
      useStore: useStore ?? _config?.useStore ?? true,
      url: updateUrl,
    ));

    try {
      if (currentVersion == null) {
        final packageInfo = await PackageInfo.fromPlatform();
        currentVersion = packageInfo.version;
      }

      // Fetch remote config if available
      cfg.RemoteConfigData? remoteConfig;
      if (_remoteConfigProvider != null) {
        try {
          remoteConfig = await _remoteConfigProvider!.fetch();
        } catch (_) {}
      }

      final updateInfo = await _platform.checkForUpdate(
        useStore: useStore ?? _config?.useStore ?? true,
        updateUrl: updateUrl ?? _config?.updateUrl,
        currentVersion: currentVersion,
      );

      if (updateInfo != null) {
        final appInfo = AppUpdateInfo.fromPlatformUpdateInfo(updateInfo);

        // Merge remote config
        final mergedInfo = AppUpdateInfo(
          updateAvailable: appInfo.updateAvailable,
          immediateUpdateAllowed: appInfo.immediateUpdateAllowed,
          flexibleUpdateAllowed: appInfo.flexibleUpdateAllowed,
          availableVersionCode: appInfo.availableVersionCode,
          updatePriority: remoteConfig?.updatePriority ?? appInfo.updatePriority,
          appStoreVersion: appInfo.appStoreVersion,
          currentVersion: appInfo.currentVersion,
          appStoreUrl: appInfo.appStoreUrl,
          directUpdate: appInfo.directUpdate,
          downloadUrl: remoteConfig?.downloadUrl ?? appInfo.downloadUrl,
          forceUpdate: remoteConfig?.forceUpdate ?? appInfo.forceUpdate,
          releaseNotes: remoteConfig?.releaseNotes ?? appInfo.releaseNotes,
        );

        _analyticsProvider.onCheckComplete(UpdateAnalyticsEvent.checkComplete(
          updateAvailable: mergedInfo.updateAvailable,
          version: mergedInfo.appStoreVersion,
        ));

        return mergedInfo;
      }

      _analyticsProvider.onCheckComplete(UpdateAnalyticsEvent.checkComplete(
        updateAvailable: false,
      ));
      return null;
    } catch (e) {
      _analyticsProvider.onCheckComplete(UpdateAnalyticsEvent(
        type: UpdateEventType.checkComplete,
        data: {'error': e.toString()},
      ));
      if (kDebugMode) {
        print('Error checking for update: $e');
      }
      return null;
    }
  }

  /// Start a flexible update.
  Future<bool> startFlexibleUpdate({String? downloadUrl}) async {
    _analyticsProvider.onDownloadStart(UpdateAnalyticsEvent.downloadStart(
      url: downloadUrl,
      flexible: true,
    ));
    _downloadStartTime = DateTime.now();

    try {
      return await _platform.startFlexibleUpdate(downloadUrl: downloadUrl);
    } catch (e) {
      _analyticsProvider.onDownloadComplete(UpdateAnalyticsEvent.installFailed(
        error: e.toString(),
      ));
      if (kDebugMode) {
        print('Error starting flexible update: $e');
      }
      return false;
    }
  }

  /// Start an immediate update (Android only, iOS will redirect to App Store).
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

  /// Complete a flexible update (Android only).
  Future<bool> completeFlexibleUpdate() async {
    try {
      final result = await _platform.completeFlexibleUpdate();
      if (result) {
        _analyticsProvider.onInstallComplete(UpdateAnalyticsEvent(
          type: UpdateEventType.installComplete,
        ));
        // Save version snapshot for rollback
        await _rollback.saveSnapshot();
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('Error completing flexible update: $e');
      }
      return false;
    }
  }

  /// Download and install update directly.
  Future<bool> downloadAndInstallUpdate(String downloadUrl) async {
    _analyticsProvider.onDownloadStart(UpdateAnalyticsEvent.downloadStart(
      url: downloadUrl,
    ));
    _downloadStartTime = DateTime.now();

    try {
      final result = await _platform.downloadAndInstallUpdate(downloadUrl);
      if (result) {
        _analyticsProvider.onDownloadComplete(UpdateAnalyticsEvent.downloadComplete());
        await _rollback.saveSnapshot();
      }
      return result;
    } catch (e) {
      _analyticsProvider.onDownloadComplete(UpdateAnalyticsEvent.installFailed(
        error: e.toString(),
      ));
      if (kDebugMode) {
        print('Error downloading and installing update: $e');
      }
      return false;
    }
  }

  /// Check if an update is available (quick check).
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

  /// Open App Store/Play Store for manual update.
  Future<bool> openStore() async {
    try {
      String storeUrl;
      if (Platform.isAndroid) {
        final packageInfo = await PackageInfo.fromPlatform();
        storeUrl = 'https://play.google.com/store/apps/details?id=${packageInfo.packageName}';
      } else if (Platform.isIOS) {
        final packageInfo = await PackageInfo.fromPlatform();
        final bundleId = packageInfo.packageName;
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

  // ==================== Listener Management ====================

  /// Set update listener for callbacks.
  void setUpdateListener(DefaultUpdateListener listener) {
    _updateListener = listener;
    _platform.setUpdateListener(listener);
  }

  /// Remove update listener.
  void removeUpdateListener() {
    _updateListener = null;
  }

  // ==================== Rollback ====================

  /// Check if rollback to a previous version is available.
  Future<RollbackInfo?> checkRollbackAvailable() async {
    final previous = await _rollback.getPreviousVersion();
    if (previous == null) return null;

    final config = _config;
    if (config == null) return null;

    return RollbackInfo(
      previousVersion: previous.version,
      previousBuildNumber: previous.buildNumber,
      rollbackAvailable: _rollback.canRollback(),
      updatedAt: previous.installedAt,
    );
  }

  /// Attempt to rollback to the previous version.
  Future<bool> rollbackToPreviousVersion() async {
    if (!_rollback.canRollback()) return false;

    _analyticsProvider.onCheckStart(UpdateAnalyticsEvent(
      type: UpdateEventType.checkStart,
      data: {'action': 'rollback'},
    ));

    final previousPath = _rollback.getPreviousVersionPath();
    if (previousPath != null && Platform.isAndroid) {
      return await downloadAndInstallUpdate(previousPath);
    }
    return false;
  }

  // ==================== Convenience Methods ====================

  /// Perform a complete update check with force update handling.
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

  // ==================== Internal Helpers ====================

  void _handleDetailedProgress(DownloadProgress progress) {
    _analyticsProvider.onDownloadProgress(UpdateAnalyticsEvent.downloadProgress(
      progress: progress.progress,
      bytesDownloaded: progress.bytesDownloaded,
      totalBytes: progress.totalBytes,
      speedBytesPerSec: progress.speedBytesPerSec,
    ));

    if (progress.state == DownloadState.completed) {
      _analyticsProvider.onDownloadComplete(UpdateAnalyticsEvent.downloadComplete(
        totalBytes: progress.totalBytes,
        duration: _downloadStartTime != null
            ? DateTime.now().difference(_downloadStartTime!)
            : null,
      ));
    }
  }

  /// Dispose of resources. Call when the plugin is no longer needed.
  void dispose() {
    stopScheduledChecks();
    _remoteConfigProvider?.clearCache();
    _analyticsProvider.clearProviders();
    _experiments.clear();
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
