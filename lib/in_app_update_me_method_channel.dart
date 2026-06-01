import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'in_app_update_me_platform_interface.dart';
import 'src/models/download_progress.dart';

class MethodChannelInAppUpdateMe extends InAppUpdateMePlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('in_app_update_me');

  UpdateListener? _listener;

  MethodChannelInAppUpdateMe() {
    methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (_listener == null) return;

    switch (call.method) {
      case 'onUpdateDownloaded':
        _listener!.onUpdateDownloaded();
        break;
      case 'onUpdateInstalled':
        _listener!.onUpdateInstalled();
        break;
      case 'onUpdateFailed':
        final error = call.arguments['error'] ?? 'Unknown error';
        _listener!.onUpdateFailed(error);
        break;
      case 'onUpdateProgress':
        _handleProgress(call.arguments);
        break;
      case 'onUpdateResult':
        final result = call.arguments['result'] ?? 'unknown';
        _listener!.onUpdateResult(result);
        break;
      case 'onUpdateDownloadStarted':
        _listener!.onUpdateDownloadStarted();
        break;
      case 'onUpdateInstallStarted':
        _listener!.onUpdateInstallStarted();
        break;
    }
  }

  void _handleProgress(dynamic arguments) {
    final args = Map<String, dynamic>.from(arguments ?? {});
    final progress = args['progress'] ?? 0;

    // Fire the simple callback for backward compatibility
    _listener!.onUpdateProgress(progress);

    // Fire detailed callback with DownloadProgress if extended data is present
    final bytesDownloaded = args['bytesDownloaded'];
    final totalBytes = args['totalBytes'];
    if (bytesDownloaded != null || totalBytes != null) {
      final stateName = args['state'] as String?;
      final state = DownloadState.values.firstWhere(
        (s) => s.name == stateName,
        orElse: () => DownloadState.downloading,
      );

      final detailedProgress = DownloadProgress(
        progress: progress,
        bytesDownloaded: bytesDownloaded ?? 0,
        totalBytes: totalBytes ?? -1,
        state: state,
      );
      _listener!.onUpdateProgressDetail(detailedProgress);
    }
  }

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<UpdateInfo?> checkForUpdate({
    bool useStore = true,
    String? updateUrl,
    String? currentVersion,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<Map<String, dynamic>>(
        'checkForUpdate',
        {
          'usePlayStore': useStore,
          'useAppStore': useStore,
          'updateUrl': updateUrl,
          'currentVersion': currentVersion,
        },
      );

      if (result != null) {
        return UpdateInfo.fromMap(result);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking for update: $e');
      }
      return null;
    }
  }

  @override
  Future<bool> startFlexibleUpdate({String? downloadUrl}) async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'startFlexibleUpdate',
        downloadUrl != null ? {'downloadUrl': downloadUrl} : null,
      );
      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Error starting flexible update: $e');
      }
      return false;
    }
  }

  @override
  Future<bool> startImmediateUpdate() async {
    try {
      final result = await methodChannel.invokeMethod<bool>('startImmediateUpdate');
      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Error starting immediate update: $e');
      }
      return false;
    }
  }

  @override
  Future<bool> completeFlexibleUpdate() async {
    try {
      final result = await methodChannel.invokeMethod<bool>('completeFlexibleUpdate');
      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Error completing flexible update: $e');
      }
      return false;
    }
  }

  @override
  Future<bool> downloadAndInstallUpdate(String downloadUrl) async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'downloadAndInstallApk',
        {'downloadUrl': downloadUrl},
      );
      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Error downloading and installing update: $e');
      }
      return false;
    }
  }

  @override
  Future<bool> isUpdateAvailable() async {
    try {
      final result = await methodChannel.invokeMethod<bool>('isUpdateAvailable');
      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking update availability: $e');
      }
      return false;
    }
  }

  @override
  void setUpdateListener(UpdateListener listener) {
    _listener = listener;
  }
}
