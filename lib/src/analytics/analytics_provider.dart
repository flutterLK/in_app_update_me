import 'analytics_event.dart';

/// Abstract interface for tracking update analytics events.
///
/// Implement this to integrate with your analytics platform
/// (Firebase Analytics, Mixpanel, Amplitude, etc.)
abstract class UpdateAnalyticsProvider {
  /// Called when an update check starts.
  void onCheckStart(UpdateAnalyticsEvent event) {}

  /// Called when an update check completes.
  void onCheckComplete(UpdateAnalyticsEvent event) {}

  /// Called when a download starts.
  void onDownloadStart(UpdateAnalyticsEvent event) {}

  /// Called during download with progress updates.
  void onDownloadProgress(UpdateAnalyticsEvent event) {}

  /// Called when a download completes.
  void onDownloadComplete(UpdateAnalyticsEvent event) {}

  /// Called when installation starts.
  void onInstallStart(UpdateAnalyticsEvent event) {}

  /// Called when installation completes.
  void onInstallComplete(UpdateAnalyticsEvent event) {}

  /// Called when installation fails.
  void onInstallFailed(UpdateAnalyticsEvent event) {}

  /// Called when the user cancels an update.
  void onCancelled(UpdateAnalyticsEvent event) {}

  /// Called on any event (generic handler).
  void onEvent(UpdateAnalyticsEvent event) {}
}
