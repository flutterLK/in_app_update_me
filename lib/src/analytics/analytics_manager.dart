import 'analytics_provider.dart';
import 'analytics_event.dart';

/// Manages analytics providers and dispatches update events.
class AnalyticsManager {
  final List<UpdateAnalyticsProvider> _providers = [];

  /// Add an analytics provider.
  void addProvider(UpdateAnalyticsProvider provider) {
    _providers.add(provider);
  }

  /// Remove an analytics provider.
  void removeProvider(UpdateAnalyticsProvider provider) {
    _providers.remove(provider);
  }

  /// Remove all providers.
  void clearProviders() {
    _providers.clear();
  }

  /// Track an event across all registered providers.
  void track(UpdateAnalyticsEvent event) {
    for (final provider in _providers) {
      provider.onEvent(event);
    }
  }

  /// Convenience: track a check started event.
  void trackCheckStarted({String? version}) {
    track(UpdateAnalyticsEvent.checkStart());
  }

  /// Convenience: track a check completed event.
  void trackCheckCompleted({required bool updateAvailable, String? version}) {
    track(UpdateAnalyticsEvent.checkComplete(
      updateAvailable: updateAvailable,
      version: version,
    ));
  }

  /// Convenience: track a download started event.
  void trackDownloadStarted({String? version}) {
    track(UpdateAnalyticsEvent.downloadStart());
  }

  /// Convenience: track a download progress event.
  void trackDownloadProgress({required int progress, String? version}) {
    track(UpdateAnalyticsEvent.downloadProgress(progress: progress));
  }

  /// Convenience: track a download completed event.
  void trackDownloadCompleted({String? version}) {
    track(UpdateAnalyticsEvent.downloadComplete());
  }

  /// Convenience: track a download failed event.
  void trackDownloadFailed({String? error, String? version}) {
    track(UpdateAnalyticsEvent.installFailed(error: error ?? 'Unknown error'));
  }
}
