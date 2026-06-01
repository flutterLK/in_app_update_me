import 'dart:convert';
import 'package:http/http.dart' as http;

/// Configuration for fetching remote update settings from a server.
class RemoteUpdateConfig {
  /// Base URL of the configuration server.
  final String serverUrl;

  /// Endpoint for fetching config (appended to serverUrl).
  final String configEndpoint;

  /// Custom HTTP headers.
  final Map<String, String> headers;

  /// How long to cache the config before re-fetching.
  final Duration cacheTimeout;

  /// Request timeout.
  final Duration timeout;

  const RemoteUpdateConfig({
    required this.serverUrl,
    this.configEndpoint = '/api/update-config',
    this.headers = const {},
    this.cacheTimeout = const Duration(hours: 1),
    this.timeout = const Duration(seconds: 30),
  });

  String get configUrl => '$serverUrl$configEndpoint';
}

/// Server-provided update configuration.
class ServerUpdateConfig {
  /// Minimum version required (force update below this).
  final String? minimumVersion;

  /// Whether to force the update.
  final bool forceUpdate;

  /// Rollout percentage (0-100). null means 100%.
  final int? rolloutPercentage;

  /// Whether the app is in maintenance mode.
  final bool maintenanceMode;

  /// Message to display to users.
  final String? message;

  /// Direct download URL override.
  final String? updateUrl;

  /// Release notes from server.
  final String? releaseNotes;

  /// Update priority (0-5).
  final int? priority;

  /// Custom data for app-specific logic.
  final Map<String, dynamic> customData;

  const ServerUpdateConfig({
    this.minimumVersion,
    this.forceUpdate = false,
    this.rolloutPercentage,
    this.maintenanceMode = false,
    this.message,
    this.updateUrl,
    this.releaseNotes,
    this.priority,
    this.customData = const {},
  });

  factory ServerUpdateConfig.fromMap(Map<String, dynamic> map) {
    return ServerUpdateConfig(
      minimumVersion: map['minimumVersion'],
      forceUpdate: map['forceUpdate'] ?? false,
      rolloutPercentage: map['rolloutPercentage'],
      maintenanceMode: map['maintenanceMode'] ?? false,
      message: map['message'],
      updateUrl: map['updateUrl'],
      releaseNotes: map['releaseNotes'],
      priority: map['priority'],
      customData: Map<String, dynamic>.from(map['customData'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
    'minimumVersion': minimumVersion,
    'forceUpdate': forceUpdate,
    'rolloutPercentage': rolloutPercentage,
    'maintenanceMode': maintenanceMode,
    'message': message,
    'updateUrl': updateUrl,
    'releaseNotes': releaseNotes,
    'priority': priority,
    'customData': customData,
  };
}

/// Fetches and caches remote update configuration.
class RemoteConfigFetcher {
  final RemoteUpdateConfig config;
  ServerUpdateConfig? _cachedConfig;
  DateTime? _lastFetchTime;

  RemoteConfigFetcher(this.config);

  /// Whether the cached config is still valid.
  bool get isCacheValid =>
      _cachedConfig != null &&
      _lastFetchTime != null &&
      DateTime.now().difference(_lastFetchTime!) < config.cacheTimeout;

  /// Fetch config from server, using cache if valid.
  Future<ServerUpdateConfig> fetch({bool forceRefresh = false}) async {
    if (!forceRefresh && isCacheValid) {
      return _cachedConfig!;
    }

    final uri = Uri.parse(config.configUrl);
    final response = await http.get(uri, headers: config.headers).timeout(
      config.timeout,
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      _cachedConfig = ServerUpdateConfig.fromMap(json);
      _lastFetchTime = DateTime.now();
      return _cachedConfig!;
    }

    throw Exception('Failed to fetch remote config: ${response.statusCode}');
  }

  /// Clear the cache.
  void clearCache() {
    _cachedConfig = null;
    _lastFetchTime = null;
  }
}
