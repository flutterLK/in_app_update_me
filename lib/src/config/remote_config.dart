import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Configuration for fetching remote update settings.
class RemoteUpdateConfig {
  final String endpoint;
  final Map<String, String>? headers;
  final Duration cacheTimeout;
  final Duration requestTimeout;

  const RemoteUpdateConfig({
    required this.endpoint,
    this.headers,
    this.cacheTimeout = const Duration(minutes: 30),
    this.requestTimeout = const Duration(seconds: 15),
  });
}

/// Data fetched from a remote update configuration server.
class RemoteConfigData {
  final bool? forceUpdate;
  final String? minimumVersion;
  final int? updatePriority;
  final bool? enabled;
  final int? rolloutPercentage;
  final String? releaseNotes;
  final String? downloadUrl;
  final String? updateMessage;
  final Map<String, dynamic>? customData;

  const RemoteConfigData({
    this.forceUpdate,
    this.minimumVersion,
    this.updatePriority,
    this.enabled,
    this.rolloutPercentage,
    this.releaseNotes,
    this.downloadUrl,
    this.updateMessage,
    this.customData,
  });

  factory RemoteConfigData.fromMap(Map<String, dynamic> map) {
    return RemoteConfigData(
      forceUpdate: map['forceUpdate'],
      minimumVersion: map['minimumVersion'],
      updatePriority: map['updatePriority'],
      enabled: map['enabled'],
      rolloutPercentage: map['rolloutPercentage'],
      releaseNotes: map['releaseNotes'],
      downloadUrl: map['downloadUrl'],
      updateMessage: map['updateMessage'],
      customData: map['customData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (forceUpdate != null) 'forceUpdate': forceUpdate,
      if (minimumVersion != null) 'minimumVersion': minimumVersion,
      if (updatePriority != null) 'updatePriority': updatePriority,
      if (enabled != null) 'enabled': enabled,
      if (rolloutPercentage != null) 'rolloutPercentage': rolloutPercentage,
      if (releaseNotes != null) 'releaseNotes': releaseNotes,
      if (downloadUrl != null) 'downloadUrl': downloadUrl,
      if (updateMessage != null) 'updateMessage': updateMessage,
      if (customData != null) 'customData': customData,
    };
  }
}

/// Cached remote config with expiry tracking.
class CachedRemoteConfig {
  RemoteConfigData? _data;
  DateTime? _fetchedAt;

  RemoteConfigData? get data => _data;
  DateTime? get fetchedAt => _fetchedAt;

  bool isExpired(Duration cacheTimeout) {
    if (_fetchedAt == null) return true;
    return DateTime.now().difference(_fetchedAt!) > cacheTimeout;
  }

  void update(RemoteConfigData data) {
    _data = data;
    _fetchedAt = DateTime.now();
  }

  void clear() {
    _data = null;
    _fetchedAt = null;
  }
}

/// Provider that fetches remote update configuration from a server.
class RemoteConfigProvider {
  final RemoteUpdateConfig config;
  final CachedRemoteConfig _cache = CachedRemoteConfig();

  RemoteConfigProvider({required this.config});

  /// Fetch remote config, returning cached data if still valid.
  Future<RemoteConfigData?> fetch({bool forceRefresh = false}) async {
    if (!forceRefresh && !_cache.isExpired(config.cacheTimeout)) {
      return _cache.data;
    }

    try {
      final uri = Uri.parse(config.endpoint);
      final response = await http.get(uri, headers: config.headers).timeout(
            config.requestTimeout,
          );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final data = RemoteConfigData.fromMap(json);
        _cache.update(data);
        return data;
      }

      if (kDebugMode) {
        print('Remote config fetch failed: HTTP ${response.statusCode}');
      }
      return _cache.data;
    } catch (e) {
      if (kDebugMode) {
        print('Remote config fetch error: $e');
      }
      return _cache.data;
    }
  }

  void clearCache() {
    _cache.clear();
  }
}
