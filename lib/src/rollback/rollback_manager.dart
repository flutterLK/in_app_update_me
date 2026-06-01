import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A snapshot of a previously installed app version.
class VersionSnapshot {
  final String version;
  final int buildNumber;
  final DateTime installedAt;
  final String? downloadPath;

  const VersionSnapshot({
    required this.version,
    required this.buildNumber,
    required this.installedAt,
    this.downloadPath,
  });

  factory VersionSnapshot.fromMap(Map<String, dynamic> map) {
    return VersionSnapshot(
      version: map['version'] ?? '',
      buildNumber: map['buildNumber'] ?? 0,
      installedAt: DateTime.parse(map['installedAt']),
      downloadPath: map['downloadPath'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'buildNumber': buildNumber,
      'installedAt': installedAt.toIso8601String(),
      'downloadPath': downloadPath,
    };
  }

  @override
  String toString() {
    return 'VersionSnapshot(version: $version, build: $buildNumber, installed: $installedAt)';
  }
}

/// Manages version snapshots for rollback capability.
///
/// Stores version history in SharedPreferences. Actual rollback
/// requires platform-specific support (e.g., reinstalling a previous APK).
class RollbackManager {
  static const String _storageKey = 'in_app_update_me_version_history';
  static const int _maxHistorySize = 5;

  List<VersionSnapshot> _history = [];

  /// Load version history from persistent storage.
  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_storageKey);
      if (json != null) {
        final list = jsonDecode(json) as List;
        _history = list
            .map((item) =>
                VersionSnapshot.fromMap(item as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading version history: $e');
      }
    }
  }

  /// Save a snapshot of the current app version.
  Future<void> saveSnapshot({String? downloadPath}) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final snapshot = VersionSnapshot(
        version: packageInfo.version,
        buildNumber: int.tryParse(packageInfo.buildNumber) ?? 0,
        installedAt: DateTime.now(),
        downloadPath: downloadPath,
      );

      _history.insert(0, snapshot);

      // Keep only the most recent entries
      if (_history.length > _maxHistorySize) {
        _history = _history.sublist(0, _maxHistorySize);
      }

      await _persist();
    } catch (e) {
      if (kDebugMode) {
        print('Error saving version snapshot: $e');
      }
    }
  }

  /// Get the previous version snapshot (one before current).
  Future<VersionSnapshot?> getPreviousVersion() async {
    if (_history.length < 2) return null;
    return _history[1];
  }

  /// Get the full version history.
  List<VersionSnapshot> getVersionHistory() {
    return List.unmodifiable(_history);
  }

  /// Check if rollback is possible (we have a previous version).
  bool canRollback() {
    return _history.length >= 2;
  }

  /// Get the download path of the previous version APK (Android only).
  String? getPreviousVersionPath() {
    if (_history.length < 2) return null;
    return _history[1].downloadPath;
  }

  /// Clear version history.
  Future<void> clearHistory() async {
    _history.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_history.map((s) => s.toMap()).toList());
    await prefs.setString(_storageKey, json);
  }
}
