/// Network requirements for downloading updates.
class NetworkConfig {
  /// Only download on WiFi connections.
  final bool wifiOnly;

  /// Allow download on metered connections (e.g., mobile data).
  /// Ignored if wifiOnly is true.
  final bool allowMetered;

  /// Prefer charging state before downloading.
  final bool preferCharging;

  const NetworkConfig({
    this.wifiOnly = false,
    this.allowMetered = true,
    this.preferCharging = false,
  });

  /// WiFi-only preset.
  static const NetworkConfig wifiOnlyPolicy = NetworkConfig(
    wifiOnly: true,
    allowMetered: false,
  );

  /// Unrestricted preset (any network).
  static const NetworkConfig unrestricted = NetworkConfig(
    wifiOnly: false,
    allowMetered: true,
  );
}
