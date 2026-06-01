/// Types of update analytics events.
enum UpdateEventType {
  checkStart,
  checkComplete,
  downloadStart,
  downloadProgress,
  downloadComplete,
  installStart,
  installComplete,
  installFailed,
  cancelled,
  rollback,
  remoteConfigFetched,
  abTestAssigned,
}

/// An analytics event for update tracking.
class UpdateAnalyticsEvent {
  /// The type of event.
  final UpdateEventType type;

  /// When the event occurred.
  final DateTime timestamp;

  /// Additional data associated with the event.
  final Map<String, dynamic> data;

  UpdateAnalyticsEvent({
    required this.type,
    DateTime? timestamp,
    this.data = const {},
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create a check start event.
  factory UpdateAnalyticsEvent.checkStart({bool useStore = true, String? url}) =>
      UpdateAnalyticsEvent(
        type: UpdateEventType.checkStart,
        data: {'useStore': useStore, 'url': url},
      );

  /// Create a check complete event.
  factory UpdateAnalyticsEvent.checkComplete({
    required bool updateAvailable,
    String? version,
    int? priority,
  }) => UpdateAnalyticsEvent(
    type: UpdateEventType.checkComplete,
    data: {
      'updateAvailable': updateAvailable,
      if (version != null) 'version': version,
      if (priority != null) 'priority': priority,
    },
  );

  /// Create a download start event.
  factory UpdateAnalyticsEvent.downloadStart({String? url, bool flexible = false}) =>
      UpdateAnalyticsEvent(
        type: UpdateEventType.downloadStart,
        data: {'url': url, 'flexible': flexible},
      );

  /// Create a download progress event.
  factory UpdateAnalyticsEvent.downloadProgress({
    required int progress,
    int? bytesDownloaded,
    int? totalBytes,
    double? speedBytesPerSec,
  }) => UpdateAnalyticsEvent(
    type: UpdateEventType.downloadProgress,
    data: {
      'progress': progress,
      if (bytesDownloaded != null) 'bytesDownloaded': bytesDownloaded,
      if (totalBytes != null) 'totalBytes': totalBytes,
      if (speedBytesPerSec != null) 'speedBytesPerSec': speedBytesPerSec,
    },
  );

  /// Create a download complete event.
  factory UpdateAnalyticsEvent.downloadComplete({int? totalBytes, Duration? duration}) =>
      UpdateAnalyticsEvent(
        type: UpdateEventType.downloadComplete,
        data: {
          if (totalBytes != null) 'totalBytes': totalBytes,
          if (duration != null) 'durationMs': duration.inMilliseconds,
        },
      );

  /// Create an install failed event.
  factory UpdateAnalyticsEvent.installFailed({required String error}) =>
      UpdateAnalyticsEvent(
        type: UpdateEventType.installFailed,
        data: {'error': error},
      );

  /// Create a cancelled event.
  factory UpdateAnalyticsEvent.cancelled({String? reason}) =>
      UpdateAnalyticsEvent(
        type: UpdateEventType.cancelled,
        data: {'reason': reason},
      );

  @override
  String toString() => 'UpdateAnalyticsEvent($type, $data)';
}
