import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_update_me/in_app_update_me.dart';
import 'package:in_app_update_me/in_app_update_me_platform_interface.dart';
import 'package:in_app_update_me/in_app_update_me_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockInAppUpdateMePlatform
    with MockPlatformInterfaceMixin
    implements InAppUpdateMePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<UpdateInfo?> checkForUpdate({
    bool useStore = true,
    String? updateUrl,
    String? currentVersion,
  }) => Future.value(UpdateInfo(
    updateAvailable: true,
    immediateUpdateAllowed: true,
    flexibleUpdateAllowed: true,
    releaseNotes: 'Bug fixes and improvements',
  ));

  @override
  Future<bool> startFlexibleUpdate({String? downloadUrl}) => Future.value(true);

  @override
  Future<bool> startImmediateUpdate() => Future.value(true);

  @override
  Future<bool> completeFlexibleUpdate() => Future.value(true);

  @override
  Future<bool> downloadAndInstallUpdate(String downloadUrl) => Future.value(true);

  @override
  Future<bool> isUpdateAvailable() => Future.value(true);

  @override
  void setUpdateListener(UpdateListener listener) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final InAppUpdateMePlatform initialPlatform = InAppUpdateMePlatform.instance;

  test('$MethodChannelInAppUpdateMe is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelInAppUpdateMe>());
  });

  test('getPlatformVersion', () async {
    InAppUpdateMe inAppUpdateMePlugin = InAppUpdateMe();
    MockInAppUpdateMePlatform fakePlatform = MockInAppUpdateMePlatform();
    InAppUpdateMePlatform.instance = fakePlatform;

    expect(await inAppUpdateMePlugin.getPlatformVersion(), '42');
  });

  test('checkForUpdate', () async {
    InAppUpdateMe inAppUpdateMePlugin = InAppUpdateMe();
    MockInAppUpdateMePlatform fakePlatform = MockInAppUpdateMePlatform();
    InAppUpdateMePlatform.instance = fakePlatform;

    final result = await inAppUpdateMePlugin.checkForUpdate(currentVersion: '1.0.0');
    expect(result, isNotNull);
    expect(result!.updateAvailable, true);
    expect(result.immediateUpdateAllowed, true);
    expect(result.flexibleUpdateAllowed, true);
    expect(result.releaseNotes, 'Bug fixes and improvements');
  });

  test('startFlexibleUpdate', () async {
    InAppUpdateMe inAppUpdateMePlugin = InAppUpdateMe();
    MockInAppUpdateMePlatform fakePlatform = MockInAppUpdateMePlatform();
    InAppUpdateMePlatform.instance = fakePlatform;

    expect(await inAppUpdateMePlugin.startFlexibleUpdate(), true);
  });

  test('startImmediateUpdate', () async {
    InAppUpdateMe inAppUpdateMePlugin = InAppUpdateMe();
    MockInAppUpdateMePlatform fakePlatform = MockInAppUpdateMePlatform();
    InAppUpdateMePlatform.instance = fakePlatform;

    expect(await inAppUpdateMePlugin.startImmediateUpdate(), true);
  });

  test('downloadAndInstallUpdate', () async {
    InAppUpdateMe inAppUpdateMePlugin = InAppUpdateMe();
    MockInAppUpdateMePlatform fakePlatform = MockInAppUpdateMePlatform();
    InAppUpdateMePlatform.instance = fakePlatform;

    expect(await inAppUpdateMePlugin.downloadAndInstallUpdate('test_url'), true);
  });

  test('UpdateConfig creation', () {
    const config = UpdateConfig(
      useStore: true,
      forceUpdate: false,
      checkInterval: Duration(hours: 24),
      showProgressDialog: true,
      autoCheckOnAppStart: true,
    );

    expect(config.useStore, true);
    expect(config.forceUpdate, false);
    expect(config.checkInterval, const Duration(hours: 24));
    expect(config.showProgressDialog, true);
    expect(config.autoCheckOnAppStart, true);
  });

  test('UpdateConfig with new fields', () {
    const config = UpdateConfig(
      useStore: true,
      networkConfig: NetworkConfig.wifiOnlyPolicy,
      channel: UpdateChannel.beta,
      userId: 'test-user-123',
    );

    expect(config.networkConfig, isNotNull);
    expect(config.networkConfig!.wifiOnly, true);
    expect(config.channel, UpdateChannel.beta);
    expect(config.userId, 'test-user-123');
  });

  test('DirectUpdateConfig creation', () {
    const config = DirectUpdateConfig(
      serverUrl: 'https://example.com',
      versionEndpoint: '/version',
      downloadEndpoint: '/download',
    );

    expect(config.serverUrl, 'https://example.com');
    expect(config.versionCheckUrl, 'https://example.com/version');
    expect(config.directDownloadUrl, 'https://example.com/download');
    expect(config.useStore, false);
  });

  test('UpdateInfo fromMap with releaseNotes', () {
    final info = UpdateInfo.fromMap({
      'updateAvailable': true,
      'immediateUpdateAllowed': false,
      'flexibleUpdateAllowed': true,
      'updatePriority': 4,
      'forceUpdate': true,
      'releaseNotes': 'New features and bug fixes',
    });

    expect(info.updateAvailable, true);
    expect(info.immediateUpdateAllowed, false);
    expect(info.flexibleUpdateAllowed, true);
    expect(info.updatePriority, 4);
    expect(info.forceUpdate, true);
    expect(info.releaseNotes, 'New features and bug fixes');
  });

  test('AppUpdateInfo shouldForceUpdate considers server forceUpdate', () {
    final info = AppUpdateInfo(
      updateAvailable: true,
      forceUpdate: true,
    );

    expect(info.shouldForceUpdate, true);
  });

  test('AppUpdateInfo shouldForceUpdate with high priority + immediate', () {
    final info = AppUpdateInfo(
      updateAvailable: true,
      updatePriority: 5,
      immediateUpdateAllowed: true,
    );

    expect(info.shouldForceUpdate, true);
  });

  test('AppUpdateInfo shouldForceUpdate is false without conditions', () {
    final info = AppUpdateInfo(
      updateAvailable: true,
      updatePriority: 2,
      immediateUpdateAllowed: false,
    );

    expect(info.shouldForceUpdate, false);
  });

  test('initialize stores config', () {
    InAppUpdateMe plugin = InAppUpdateMe();
    const config = UpdateConfig(
      useStore: false,
      forceUpdate: true,
      checkInterval: Duration(hours: 1),
    );

    plugin.initialize(config);
    expect(plugin.config, isNotNull);
    expect(plugin.config!.useStore, false);
    expect(plugin.config!.forceUpdate, true);
  });

  // New v2.0.0 feature tests

  test('DownloadProgress model', () {
    final progress = DownloadProgress(
      progress: 50,
      bytesDownloaded: 5 * 1024 * 1024,
      totalBytes: 10 * 1024 * 1024,
      speedBytesPerSec: 1024 * 1024,
      estimatedTimeRemaining: const Duration(seconds: 5),
      state: DownloadState.downloading,
    );

    expect(progress.progress, 50);
    expect(progress.downloadedSize, '5.0 MB');
    expect(progress.totalSize, '10.0 MB');
    expect(progress.isTotalKnown, true);
    expect(progress.state, DownloadState.downloading);
  });

  test('DownloadProgress.fromBytes', () {
    final progress = DownloadProgress.fromBytes(
      bytesDownloaded: 1024 * 1024,
      totalBytes: 5 * 1024 * 1024,
      elapsed: const Duration(seconds: 2),
    );

    expect(progress.progress, 20);
    expect(progress.bytesDownloaded, 1024 * 1024);
    expect(progress.totalBytes, 5 * 1024 * 1024);
  });

  test('NetworkConfig presets', () {
    final wifi = NetworkConfig.wifiOnlyPolicy;
    expect(wifi.wifiOnly, true);
    expect(wifi.allowMetered, false);

    const unrestricted = NetworkConfig.unrestricted;
    expect(unrestricted.wifiOnly, false);
    expect(unrestricted.allowMetered, true);
  });

  test('NetworkPolicy presets', () {
    expect(NetworkPolicy.wifiOnly.requirement, NetworkRequirement.wifiOnly);
    expect(NetworkPolicy.unmeteredOnly.requirement, NetworkRequirement.unmeteredOnly);
    expect(NetworkPolicy.defaultPolicy.requirement, NetworkRequirement.any);
  });

  test('AnalyticsManager tracks events', () {
    final manager = AnalyticsManager();
    int eventCount = 0;
    manager.addProvider(_TestAnalyticsProvider(() => eventCount++));
    manager.trackCheckStarted();
    manager.trackDownloadProgress(progress: 50);
    expect(eventCount, 2);
  });

  test('ExperimentManager variant assignment', () {
    final manager = ExperimentManager();
    const variant = ExperimentVariant(id: 'treatment', name: 'Treatment A');
    manager.assignVariant('exp1', variant);
    expect(manager.getVariant('exp1'), variant);
    expect(manager.hasVariant('exp1'), true);
    expect(manager.hasVariant('exp2'), false);
  });

  test('RollbackManager version tracking', () {
    final manager = RollbackManager();
    expect(manager.canRollback(), false);
    expect(manager.getVersionHistory(), isEmpty);
  });

  test('RemoteConfigData fromMap', () {
    final data = RemoteConfigData.fromMap({
      'forceUpdate': true,
      'minimumVersion': '2.0.0',
      'updatePriority': 4,
      'releaseNotes': 'Important update',
      'downloadUrl': 'https://example.com/app.apk',
    });

    expect(data.forceUpdate, true);
    expect(data.minimumVersion, '2.0.0');
    expect(data.updatePriority, 4);
    expect(data.releaseNotes, 'Important update');
    expect(data.downloadUrl, 'https://example.com/app.apk');
  });

  test('ABTestConfig and manager', () {
    final config = ABTestConfig(
      experimentId: 'exp1',
      variants: {
        'control': const UpdateConfig(useStore: true),
        'treatment': const UpdateConfig(useStore: false),
      },
    );

    expect(config.experimentId, 'exp1');
    expect(config.variants.length, 2);
    expect(config.defaultVariant, 'control');
  });

  test('UpdateDialogTheme creation', () {
    const theme = UpdateDialogTheme(
      primaryColor: Color(0xFF2196F3),
      progressColor: Color(0xFF4CAF50),
      iconColor: Color(0xFFFF9800),
      updateButtonText: 'Go!',
      laterButtonText: 'Skip',
    );

    expect(theme.primaryColor, const Color(0xFF2196F3));
    expect(theme.updateButtonText, 'Go!');
    expect(theme.laterButtonText, 'Skip');
  });

  test('UpdateStrings default is English', () {
    const strings = UpdateStrings();
    expect(strings.updateAvailableTitle, 'Update Available');
    expect(strings.updateRequiredTitle, 'Update Required');
    expect(strings.laterButton, 'Later');
    expect(strings.updateNowButton, 'Update Now');
  });

  test('RemoteUpdateConfig construction', () {
    const config = RemoteUpdateConfig(
      endpoint: 'https://example.com/api/config',
      headers: {'Authorization': 'Bearer token'},
    );

    expect(config.endpoint, 'https://example.com/api/config');
    expect(config.headers!['Authorization'], 'Bearer token');
    expect(config.cacheTimeout, const Duration(minutes: 30));
  });

  test('CachedRemoteConfig expiry', () {
    final cache = CachedRemoteConfig();
    expect(cache.isExpired(const Duration(minutes: 1)), true);

    cache.update(const RemoteConfigData(forceUpdate: true));
    expect(cache.isExpired(const Duration(hours: 1)), false);
    expect(cache.isExpired(Duration.zero), true);
  });

  test('UpdateChannel enum values', () {
    expect(UpdateChannel.stable.name, 'stable');
    expect(UpdateChannel.beta.name, 'beta');
    expect(UpdateChannel.canary.name, 'canary');
    expect(UpdateChannel.internal.name, 'internal');
  });

  test('RollbackConfig defaults', () {
    const config = RollbackConfig();
    expect(config.enabled, true);
    expect(config.maxRollbackWindow, const Duration(hours: 48));
    expect(config.requireConfirmation, true);
  });

  test('UpdateAnalyticsEvent creation', () {
    final event = UpdateAnalyticsEvent.checkStart(useStore: true);
    expect(event.type, UpdateEventType.checkStart);
    expect(event.data['useStore'], true);
  });
}

class _TestAnalyticsProvider extends UpdateAnalyticsProvider {
  final VoidCallback onEventCalled;
  _TestAnalyticsProvider(this.onEventCalled);

  @override
  void onEvent(UpdateAnalyticsEvent event) {
    onEventCalled();
  }
}

typedef VoidCallback = void Function();
