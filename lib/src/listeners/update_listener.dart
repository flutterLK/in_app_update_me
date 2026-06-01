import '../models/download_progress.dart';

/// Base abstract class for update event listeners.
abstract class UpdateListener {
  void onUpdateDownloaded();
  void onUpdateInstalled();
  void onUpdateFailed(String error);
  void onUpdateProgress(int progress);
  void onUpdateProgressDetail(DownloadProgress progress) {}
  void onUpdateResult(String result);
  void onUpdateDownloadStarted();
  void onUpdateInstallStarted();
}

/// Extended listener with default empty implementations and additional callbacks.
abstract class AppUpdateListener extends UpdateListener {
  @override
  void onUpdateDownloaded() {}

  @override
  void onUpdateInstalled() {}

  @override
  void onUpdateFailed(String error) {}

  @override
  void onUpdateProgress(int progress) {}

  @override
  void onUpdateProgressDetail(DownloadProgress progress) {}

  @override
  void onUpdateResult(String result) {}

  @override
  void onUpdateDownloadStarted() {}

  @override
  void onUpdateInstallStarted() {}

  void onUpdateCheckCompleted(bool updateAvailable) {}
  void onUpdateCancelled() {}
  void onUpdateNotAvailable() {}
}

class DefaultUpdateListener extends AppUpdateListener {
  final Function()? onDownloaded;
  final Function()? onInstalled;
  final Function(String)? onFailed;
  final Function(int)? onProgress;
  final Function(DownloadProgress)? onProgressDetail;
  final Function(String)? onResult;
  final Function(bool)? onCheckCompleted;
  final Function()? onCancelled;
  final Function()? onNotAvailable;
  final Function()? onDownloadStarted;
  final Function()? onInstallStarted;

  DefaultUpdateListener({
    this.onDownloaded,
    this.onInstalled,
    this.onFailed,
    this.onProgress,
    this.onProgressDetail,
    this.onResult,
    this.onCheckCompleted,
    this.onCancelled,
    this.onNotAvailable,
    this.onDownloadStarted,
    this.onInstallStarted,
  });

  @override
  void onUpdateDownloaded() {
    onDownloaded?.call();
  }

  @override
  void onUpdateInstalled() {
    onInstalled?.call();
  }

  @override
  void onUpdateFailed(String error) {
    onFailed?.call(error);
  }

  @override
  void onUpdateProgress(int progress) {
    onProgress?.call(progress);
  }

  @override
  void onUpdateProgressDetail(DownloadProgress progress) {
    onProgressDetail?.call(progress);
    // Also call the simple progress callback for backward compatibility
    onProgress?.call(progress.progress);
  }

  @override
  void onUpdateResult(String result) {
    onResult?.call(result);

    switch (result) {
      case 'success':
        break;
      case 'cancelled':
        onUpdateCancelled();
        break;
      case 'failed':
        onUpdateFailed('Update failed');
        break;
    }
  }

  @override
  void onUpdateCheckCompleted(bool updateAvailable) {
    onCheckCompleted?.call(updateAvailable);
    if (!updateAvailable) {
      onUpdateNotAvailable();
    }
  }

  @override
  void onUpdateCancelled() {
    onCancelled?.call();
  }

  @override
  void onUpdateNotAvailable() {
    onNotAvailable?.call();
  }

  @override
  void onUpdateDownloadStarted() {
    onDownloadStarted?.call();
  }

  @override
  void onUpdateInstallStarted() {
    onInstallStarted?.call();
  }
}
