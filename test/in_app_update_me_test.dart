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

  test('DirectUpdateConfig creation', () {
    const config = DirectUpdateConfig(
      serverUrl: 'https://example.com',
      versionEndpoint: '/version',
      downloadEndpoint: '/download',
    );

    expect(config.serverUrl, 'https://example.com');
    expect(config.versionCheckUrl, 'https://example.com/version');
    expect(config.downloadUrl, 'https://example.com/download');
    expect(config.useStore, false);
  });

  test('UpdateInfo fromMap', () {
    final info = UpdateInfo.fromMap({
      'updateAvailable': true,
      'immediateUpdateAllowed': false,
      'flexibleUpdateAllowed': true,
      'updatePriority': 4,
      'forceUpdate': true,
    });

    expect(info.updateAvailable, true);
    expect(info.immediateUpdateAllowed, false);
    expect(info.flexibleUpdateAllowed, true);
    expect(info.updatePriority, 4);
    expect(info.forceUpdate, true);
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
}
