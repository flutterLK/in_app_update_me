/// Network requirement for update downloads.
enum NetworkRequirement {
  /// Allow downloads on any network (WiFi, cellular, etc.),
  any,

  /// Only allow downloads on WiFi networks.
  wifiOnly,

  /// Only allow downloads on unmetered networks.
  unmeteredOnly,
}

/// Policy for controlling update download network behavior.
class NetworkPolicy {
  final NetworkRequirement requirement;
  final bool allowRoaming;

  const NetworkPolicy({
    this.requirement = NetworkRequirement.any,
    this.allowRoaming = false,
  });

  /// Default policy: any network, no roaming.
  static const NetworkPolicy defaultPolicy = NetworkPolicy();

  /// WiFi-only policy.
  static const NetworkPolicy wifiOnly = NetworkPolicy(
    requirement: NetworkRequirement.wifiOnly,
  );

  /// Unmetered-only policy (WiFi, ethernet, etc.).
  static const NetworkPolicy unmeteredOnly = NetworkPolicy(
    requirement: NetworkRequirement.unmeteredOnly,
  );

  Map<String, dynamic> toMap() {
    return {
      'requirement': requirement.name,
      'allowRoaming': allowRoaming,
    };
  }

  @override
  String toString() {
    return 'NetworkPolicy(requirement: ${requirement.name}, allowRoaming: $allowRoaming)';
  }
}
