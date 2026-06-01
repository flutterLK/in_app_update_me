import 'analytics_provider.dart';
import 'analytics_event.dart';

/// An analytics provider that forwards events to multiple providers.
class CompositeAnalyticsProvider extends UpdateAnalyticsProvider {
  final List<UpdateAnalyticsProvider> _providers;

  CompositeAnalyticsProvider([List<UpdateAnalyticsProvider>? providers])
      : _providers = providers ?? [];

  /// Add a provider.
  void addProvider(UpdateAnalyticsProvider provider) {
    _providers.add(provider);
  }

  /// Remove a provider.
  void removeProvider(UpdateAnalyticsProvider provider) {
    _providers.remove(provider);
  }

  /// All registered providers.
  List<UpdateAnalyticsProvider> get providers => List.unmodifiable(_providers);

  /// Remove all providers.
  void clearProviders() {
    _providers.clear();
  }

  @override
  void onCheckStart(UpdateAnalyticsEvent event) {
    for (final p in _providers) {
      p.onCheckStart(event);
      p.onEvent(event);
    }
  }

  @override
  void onCheckComplete(UpdateAnalyticsEvent event) {
    for (final p in _providers) {
      p.onCheckComplete(event);
      p.onEvent(event);
    }
  }

  @override
  void onDownloadStart(UpdateAnalyticsEvent event) {
    for (final p in _providers) {
      p.onDownloadStart(event);
      p.onEvent(event);
    }
  }

  @override
  void onDownloadProgress(UpdateAnalyticsEvent event) {
    for (final p in _providers) {
      p.onDownloadProgress(event);
      p.onEvent(event);
    }
  }

  @override
  void onDownloadComplete(UpdateAnalyticsEvent event) {
    for (final p in _providers) {
      p.onDownloadComplete(event);
      p.onEvent(event);
    }
  }

  @override
  void onInstallStart(UpdateAnalyticsEvent event) {
    for (final p in _providers) {
      p.onInstallStart(event);
      p.onEvent(event);
    }
  }

  @override
  void onInstallComplete(UpdateAnalyticsEvent event) {
    for (final p in _providers) {
      p.onInstallComplete(event);
      p.onEvent(event);
    }
  }

  @override
  void onInstallFailed(UpdateAnalyticsEvent event) {
    for (final p in _providers) {
      p.onInstallFailed(event);
      p.onEvent(event);
    }
  }

  @override
  void onCancelled(UpdateAnalyticsEvent event) {
    for (final p in _providers) {
      p.onCancelled(event);
      p.onEvent(event);
    }
  }
}
