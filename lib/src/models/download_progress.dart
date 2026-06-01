/// State of the download process.
enum DownloadState {
  idle,
  checking,
  downloading,
  installing,
  completed,
  failed,
  cancelled,
}

/// Detailed download progress information.
class DownloadProgress {
  /// Progress percentage (0-100).
  final int progress;

  /// Bytes downloaded so far.
  final int bytesDownloaded;

  /// Total bytes to download (-1 if unknown).
  final int totalBytes;

  /// Download speed in bytes per second.
  final double speedBytesPerSec;

  /// Estimated time remaining.
  final Duration? estimatedTimeRemaining;

  /// Current download state.
  final DownloadState state;

  /// Error message if state is failed.
  final String? error;

  const DownloadProgress({
    required this.progress,
    this.bytesDownloaded = 0,
    this.totalBytes = -1,
    this.speedBytesPerSec = 0,
    this.estimatedTimeRemaining,
    this.state = DownloadState.idle,
    this.error,
  });

  /// Whether the total size is known.
  bool get isTotalKnown => totalBytes > 0;

  /// Human-readable downloaded size.
  String get downloadedSize => _formatBytes(bytesDownloaded);

  /// Human-readable total size.
  String get totalSize => isTotalKnown ? _formatBytes(totalBytes) : 'Unknown';

  /// Human-readable speed.
  String get speedText => '${_formatBytes(speedBytesPerSec.round())}/s';

  /// Human-readable ETA.
  String get etaText {
    if (estimatedTimeRemaining == null) return '--';
    final eta = estimatedTimeRemaining!;
    if (eta.inHours > 0) return '${eta.inHours}h ${eta.inMinutes.remainder(60)}m';
    if (eta.inMinutes > 0) return '${eta.inMinutes}m ${eta.inSeconds.remainder(60)}s';
    return '${eta.inSeconds}s';
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Create a progress update from raw values, calculating speed and ETA.
  factory DownloadProgress.fromBytes({
    required int bytesDownloaded,
    required int totalBytes,
    required Duration elapsed,
    DownloadState state = DownloadState.downloading,
  }) {
    final speedBytesPerSec = elapsed.inSeconds > 0
        ? bytesDownloaded / elapsed.inSeconds
        : 0.0;

    Duration? eta;
    if (speedBytesPerSec > 0 && totalBytes > 0) {
      final remainingBytes = totalBytes - bytesDownloaded;
      eta = Duration(seconds: (remainingBytes / speedBytesPerSec).round());
    }

    final progress = totalBytes > 0
        ? ((bytesDownloaded * 100) / totalBytes).round().clamp(0, 100)
        : 0;

    return DownloadProgress(
      progress: progress,
      bytesDownloaded: bytesDownloaded,
      totalBytes: totalBytes,
      speedBytesPerSec: speedBytesPerSec,
      estimatedTimeRemaining: eta,
      state: state,
    );
  }

  @override
  String toString() =>
      'DownloadProgress($progress%, $downloadedSize/$totalSize, $speedText, ETA: $etaText)';
}
