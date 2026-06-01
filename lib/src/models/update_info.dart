/// Platform-level update info returned from native code.
class UpdateInfo {
  final bool updateAvailable;
  final bool immediateUpdateAllowed;
  final bool flexibleUpdateAllowed;
  final int? availableVersionCode;
  final int? updatePriority;
  final String? appStoreVersion;
  final String? currentVersion;
  final String? appStoreUrl;
  final bool? directUpdate;
  final String? downloadUrl;
  final bool forceUpdate;
  final String? releaseNotes;

  UpdateInfo({
    required this.updateAvailable,
    this.immediateUpdateAllowed = false,
    this.flexibleUpdateAllowed = false,
    this.availableVersionCode,
    this.updatePriority,
    this.appStoreVersion,
    this.currentVersion,
    this.appStoreUrl,
    this.directUpdate,
    this.downloadUrl,
    this.forceUpdate = false,
    this.releaseNotes,
  });

  factory UpdateInfo.fromMap(Map<String, dynamic> map) {
    return UpdateInfo(
      updateAvailable: map['updateAvailable'] ?? false,
      immediateUpdateAllowed: map['immediateUpdateAllowed'] ?? false,
      flexibleUpdateAllowed: map['flexibleUpdateAllowed'] ?? false,
      availableVersionCode: map['availableVersionCode'],
      updatePriority: map['updatePriority'],
      appStoreVersion: map['appStoreVersion'],
      currentVersion: map['currentVersion'],
      appStoreUrl: map['appStoreUrl'],
      directUpdate: map['directUpdate'],
      downloadUrl: map['downloadUrl'],
      forceUpdate: map['forceUpdate'] ?? false,
      releaseNotes: map['releaseNotes'],
    );
  }
}

/// Public-facing update info model with computed properties.
class AppUpdateInfo {
  final bool updateAvailable;
  final bool immediateUpdateAllowed;
  final bool flexibleUpdateAllowed;
  final int? availableVersionCode;
  final int? updatePriority;
  final String? appStoreVersion;
  final String? currentVersion;
  final String? appStoreUrl;
  final bool? directUpdate;
  final String? downloadUrl;
  final bool forceUpdate;
  final String? releaseNotes;

  AppUpdateInfo({
    required this.updateAvailable,
    this.immediateUpdateAllowed = false,
    this.flexibleUpdateAllowed = false,
    this.availableVersionCode,
    this.updatePriority,
    this.appStoreVersion,
    this.currentVersion,
    this.appStoreUrl,
    this.directUpdate,
    this.downloadUrl,
    this.forceUpdate = false,
    this.releaseNotes,
  });

  factory AppUpdateInfo.fromPlatformUpdateInfo(UpdateInfo platformInfo) {
    return AppUpdateInfo(
      updateAvailable: platformInfo.updateAvailable,
      immediateUpdateAllowed: platformInfo.immediateUpdateAllowed,
      flexibleUpdateAllowed: platformInfo.flexibleUpdateAllowed,
      availableVersionCode: platformInfo.availableVersionCode,
      updatePriority: platformInfo.updatePriority,
      appStoreVersion: platformInfo.appStoreVersion,
      currentVersion: platformInfo.currentVersion,
      appStoreUrl: platformInfo.appStoreUrl,
      directUpdate: platformInfo.directUpdate,
      downloadUrl: platformInfo.downloadUrl,
      forceUpdate: platformInfo.forceUpdate,
      releaseNotes: platformInfo.releaseNotes,
    );
  }

  /// Check if this is a high priority update
  bool get isHighPriority => updatePriority != null && updatePriority! >= 4;

  /// Check if this is a medium priority update
  bool get isMediumPriority => updatePriority != null && updatePriority! >= 2;

  // Fix #15: Consider server-declared force update OR high priority + immediate allowed
  bool get shouldForceUpdate =>
      forceUpdate || (isHighPriority && immediateUpdateAllowed);

  @override
  String toString() {
    return 'AppUpdateInfo('
        'updateAvailable: $updateAvailable, '
        'immediateUpdateAllowed: $immediateUpdateAllowed, '
        'flexibleUpdateAllowed: $flexibleUpdateAllowed, '
        'availableVersionCode: $availableVersionCode, '
        'updatePriority: $updatePriority, '
        'appStoreVersion: $appStoreVersion, '
        'currentVersion: $currentVersion, '
        'directUpdate: $directUpdate, '
        'downloadUrl: $downloadUrl, '
        'forceUpdate: $forceUpdate, '
        'releaseNotes: $releaseNotes'
        ')';
  }
}
