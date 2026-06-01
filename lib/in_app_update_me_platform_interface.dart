import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'in_app_update_me_method_channel.dart';
import 'src/models/update_info.dart';
import 'src/listeners/update_listener.dart';

// Re-export for backward compatibility with test mocks
export 'src/models/update_info.dart' show UpdateInfo;
export 'src/listeners/update_listener.dart' show UpdateListener;

abstract class InAppUpdateMePlatform extends PlatformInterface {
  InAppUpdateMePlatform() : super(token: _token);

  static final Object _token = Object();
  static InAppUpdateMePlatform _instance = MethodChannelInAppUpdateMe();

  static InAppUpdateMePlatform get instance => _instance;

  static set instance(InAppUpdateMePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  Future<UpdateInfo?> checkForUpdate({
    bool useStore = true,
    String? updateUrl,
    String? currentVersion,
  }) {
    throw UnimplementedError('checkForUpdate() has not been implemented.');
  }

  Future<bool> startFlexibleUpdate({String? downloadUrl}) {
    throw UnimplementedError('startFlexibleUpdate() has not been implemented.');
  }

  Future<bool> startImmediateUpdate() {
    throw UnimplementedError('startImmediateUpdate() has not been implemented.');
  }

  Future<bool> completeFlexibleUpdate() {
    throw UnimplementedError('completeFlexibleUpdate() has not been implemented.');
  }

  Future<bool> downloadAndInstallUpdate(String downloadUrl) {
    throw UnimplementedError('downloadAndInstallUpdate() has not been implemented.');
  }

  Future<bool> isUpdateAvailable() {
    throw UnimplementedError('isUpdateAvailable() has not been implemented.');
  }

  void setUpdateListener(UpdateListener listener) {
    throw UnimplementedError('setUpdateListener() has not been implemented.');
  }
}
