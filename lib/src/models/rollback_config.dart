/// Configuration for update rollback functionality.
class RollbackConfig {
  /// Whether rollback is enabled.
  final bool enabled;

  /// Maximum time window after update during which rollback is allowed.
  final Duration maxRollbackWindow;

  /// Whether to show a confirmation dialog before rollback.
  final bool requireConfirmation;

  const RollbackConfig({
    this.enabled = true,
    this.maxRollbackWindow = const Duration(hours: 48),
    this.requireConfirmation = true,
  });
}

/// Information about a potential rollback.
class RollbackInfo {
  /// The version that can be rolled back to.
  final String previousVersion;

  /// The build number of the previous version.
  final int? previousBuildNumber;

  /// Whether rollback is currently available.
  final bool rollbackAvailable;

  /// Deadline after which rollback is no longer possible.
  final DateTime? rollbackDeadline;

  /// When the current update was installed.
  final DateTime? updatedAt;

  const RollbackInfo({
    required this.previousVersion,
    this.previousBuildNumber,
    this.rollbackAvailable = false,
    this.rollbackDeadline,
    this.updatedAt,
  });

  factory RollbackInfo.fromMap(Map<String, dynamic> map) {
    return RollbackInfo(
      previousVersion: map['previousVersion'] ?? '',
      previousBuildNumber: map['previousBuildNumber'],
      rollbackAvailable: map['rollbackAvailable'] ?? false,
      rollbackDeadline: map['rollbackDeadline'] != null
          ? DateTime.tryParse(map['rollbackDeadline'])
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    'previousVersion': previousVersion,
    'previousBuildNumber': previousBuildNumber,
    'rollbackAvailable': rollbackAvailable,
    'rollbackDeadline': rollbackDeadline?.toIso8601String(),
    'updatedAt': updatedAt?.toIso8601String(),
  };

  @override
  String toString() =>
      'RollbackInfo(v$previousVersion, available: $rollbackAvailable)';
}
