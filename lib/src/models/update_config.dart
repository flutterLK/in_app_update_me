import 'network_config.dart';

/// Update channel for targeting specific release tracks.
enum UpdateChannel {
  stable,
  beta,
  canary,
  internal,
}

class UpdateConfig {
  final bool useStore;
  final String? updateUrl;
  final String? currentVersion;
  final bool forceUpdate;
  final Duration checkInterval;
  final bool showProgressDialog;
  final bool autoCheckOnAppStart;
  final UpdatePriority minimumPriority;

  /// Network requirements for downloading updates.
  final NetworkConfig? networkConfig;

  /// URL for fetching server-side update configuration.
  final String? serverConfigUrl;

  /// Custom headers for server config requests.
  final Map<String, String>? serverHeaders;

  /// User identifier for A/B testing bucket assignment.
  final String? userId;

  /// Update channel (stable, beta, canary, internal).
  final UpdateChannel channel;

  const UpdateConfig({
    this.useStore = true,
    this.updateUrl,
    this.currentVersion,
    this.forceUpdate = false,
    this.checkInterval = const Duration(hours: 24),
    this.showProgressDialog = true,
    this.autoCheckOnAppStart = true,
    this.minimumPriority = UpdatePriority.low,
    this.networkConfig,
    this.serverConfigUrl,
    this.serverHeaders,
    this.userId,
    this.channel = UpdateChannel.stable,
  });

  UpdateConfig copyWith({
    bool? useStore,
    String? updateUrl,
    String? currentVersion,
    bool? forceUpdate,
    Duration? checkInterval,
    bool? showProgressDialog,
    bool? autoCheckOnAppStart,
    UpdatePriority? minimumPriority,
    NetworkConfig? networkConfig,
    String? serverConfigUrl,
    Map<String, String>? serverHeaders,
    String? userId,
    UpdateChannel? channel,
  }) {
    return UpdateConfig(
      useStore: useStore ?? this.useStore,
      updateUrl: updateUrl ?? this.updateUrl,
      currentVersion: currentVersion ?? this.currentVersion,
      forceUpdate: forceUpdate ?? this.forceUpdate,
      checkInterval: checkInterval ?? this.checkInterval,
      showProgressDialog: showProgressDialog ?? this.showProgressDialog,
      autoCheckOnAppStart: autoCheckOnAppStart ?? this.autoCheckOnAppStart,
      minimumPriority: minimumPriority ?? this.minimumPriority,
      networkConfig: networkConfig ?? this.networkConfig,
      serverConfigUrl: serverConfigUrl ?? this.serverConfigUrl,
      serverHeaders: serverHeaders ?? this.serverHeaders,
      userId: userId ?? this.userId,
      channel: channel ?? this.channel,
    );
  }

  @override
  String toString() {
    return 'UpdateConfig('
        'useStore: $useStore, '
        'updateUrl: $updateUrl, '
        'forceUpdate: $forceUpdate, '
        'checkInterval: $checkInterval, '
        'showProgressDialog: $showProgressDialog, '
        'autoCheckOnAppStart: $autoCheckOnAppStart, '
        'minimumPriority: $minimumPriority, '
        'channel: $channel'
        ')';
  }
}

enum UpdatePriority {
  low(0),
  medium(2),
  high(4),
  critical(5);

  const UpdatePriority(this.value);
  final int value;
}

class DirectUpdateConfig extends UpdateConfig {
  final String serverUrl;
  final String versionEndpoint;
  final String downloadEndpoint;
  final Map<String, String>? headers;
  final Duration timeout;

  const DirectUpdateConfig({
    required this.serverUrl,
    this.versionEndpoint = '/version',
    this.downloadEndpoint = '/download',
    this.headers,
    this.timeout = const Duration(seconds: 30),
    super.useStore = false,
    super.forceUpdate = false,
    super.checkInterval = const Duration(hours: 6),
    super.showProgressDialog = true,
    super.autoCheckOnAppStart = true,
    super.minimumPriority = UpdatePriority.low,
    super.networkConfig,
    super.userId,
    super.channel,
  });

  String get versionCheckUrl => serverUrl + versionEndpoint;
  String get directDownloadUrl => serverUrl + downloadEndpoint;

  @override
  DirectUpdateConfig copyWith({
    String? serverUrl,
    String? versionEndpoint,
    String? downloadEndpoint,
    Map<String, String>? headers,
    Duration? timeout,
    bool? useStore,
    String? updateUrl,
    String? currentVersion,
    bool? forceUpdate,
    Duration? checkInterval,
    bool? showProgressDialog,
    bool? autoCheckOnAppStart,
    UpdatePriority? minimumPriority,
    NetworkConfig? networkConfig,
    String? serverConfigUrl,
    Map<String, String>? serverHeaders,
    String? userId,
    UpdateChannel? channel,
  }) {
    return DirectUpdateConfig(
      serverUrl: serverUrl ?? this.serverUrl,
      versionEndpoint: versionEndpoint ?? this.versionEndpoint,
      downloadEndpoint: downloadEndpoint ?? this.downloadEndpoint,
      headers: headers ?? this.headers,
      timeout: timeout ?? this.timeout,
      useStore: useStore ?? this.useStore,
      forceUpdate: forceUpdate ?? this.forceUpdate,
      checkInterval: checkInterval ?? this.checkInterval,
      showProgressDialog: showProgressDialog ?? this.showProgressDialog,
      autoCheckOnAppStart: autoCheckOnAppStart ?? this.autoCheckOnAppStart,
      minimumPriority: minimumPriority ?? this.minimumPriority,
      networkConfig: networkConfig ?? this.networkConfig,
      userId: userId ?? this.userId,
      channel: channel ?? this.channel,
    );
  }
}
