# in_app_update_me

<div align="center">

  [![Flutter](https://img.shields.io/badge/Flutter->=3.0.0-blue.svg)](https://flutter.dev/)
  [![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-lightgrey.svg)]()
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

  **A comprehensive Flutter plugin for in-app updates with server-side configuration, A/B testing, analytics, and full UI customization.**
</div>

---

## ✨ Features

- **Cross-platform**: Works on both Android and iOS
- **Play Store Updates**: Google Play In-App Updates API support
- **App Store Updates**: App Store redirect and version checking
- **Direct Updates**: Download and install APK/IPA files directly
- **Force Updates**: Mandatory updates with blocking UI
- **Flexible Updates**: Background downloads (Android & iOS)
- **Enhanced Progress Tracking**: Bytes downloaded, speed, ETA, state
- **Server-side Configuration**: Fetch update config from remote server
- **A/B Testing**: Deterministic variant assignment for update strategies
- **Update Rollback**: Version history tracking and rollback capability
- **Analytics Integration**: Pluggable provider for tracking update events
- **Network-aware**: WiFi-only download option
- **Scheduled Checks**: Periodic automatic update checks
- **Release Notes**: Display changelogs in update dialogs
- **UI Customization**: Theme colors, styles, custom builders
- **i18n**: 8 built-in languages (en, es, fr, de, ja, zh, ko, pt)
- **Update Channels**: stable, beta, canary, internal

## 📱 Platform Support

| Platform | Store Updates | Direct Updates | Force Updates | Flexible Updates |
|----------|---------------|----------------|---------------|------------------|
| Android  | ✅ Google Play | ✅ APK Download | ✅ | ✅ Background |
| iOS      | ✅ App Store   | ✅ Enterprise/Ad-hoc | ✅ | ✅ Background* |

*iOS flexible updates work for enterprise and ad-hoc distributed apps with background downloads

## 📦 Installation

```yaml
dependencies:
  in_app_update_me: ^2.0.0
```

```bash
flutter pub get
```

## 🚀 Quick Start

### 1. Basic Setup

```dart
import 'package:in_app_update_me/in_app_update_me.dart';

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final InAppUpdateMe _inAppUpdate = InAppUpdateMe();

  @override
  void initState() {
    super.initState();
    _initializeUpdates();
  }

  void _initializeUpdates() {
    _inAppUpdate.initialize(UpdateConfig(
      useStore: true,
      checkInterval: Duration(hours: 24),
      autoCheckOnAppStart: true,
    ));

    _inAppUpdate.setUpdateListener(DefaultUpdateListener(
      onProgress: (progress) => print('Download progress: $progress%'),
      onProgressDetail: (detail) {
        print('Speed: ${detail.speedText}, ETA: ${detail.etaText}');
      },
      onDownloaded: () => print('Update downloaded'),
      onInstalled: () => print('Update installed'),
      onFailed: (error) => print('Update failed: $error'),
    ));
  }

  Future<void> _checkForUpdates() async {
    final updateInfo = await _inAppUpdate.checkForUpdate();
    if (updateInfo?.updateAvailable == true && mounted) {
      UpdateAvailableDialog.show(context, updateInfo!, UpdateConfig(useStore: true));
    }
  }
}
```

### 2. Force Updates

```dart
Future<void> _performForceUpdateCheck() async {
  final result = await _inAppUpdate.performUpdateCheck(
    UpdateConfig(useStore: true, forceUpdate: true, minimumPriority: UpdatePriority.high),
  );

  if (result.updateAvailable && result.updateInfo != null && mounted) {
    ForceUpdateDialog.show(context, result.updateInfo!, UpdateConfig(forceUpdate: true));
  }
}
```

### 3. Direct Updates with Server Config

```dart
Future<void> _checkDirectUpdate() async {
  final updateInfo = await _inAppUpdate.checkForUpdate(
    useStore: false,
    updateUrl: 'https://your-server.com/api/check-update',
    currentVersion: '1.0.0',
  );

  if (updateInfo?.updateAvailable == true) {
    await _inAppUpdate.downloadAndInstallUpdate(updateInfo!.downloadUrl!);
  }
}
```

### 4. Flexible Updates (Android & iOS)

```dart
Future<void> _startFlexibleUpdate() async {
  final updateInfo = await _inAppUpdate.checkForUpdate();
  if (updateInfo?.flexibleUpdateAllowed == true) {
    await _inAppUpdate.startFlexibleUpdate(downloadUrl: updateInfo?.downloadUrl);
    // User continues using app while download happens
    await _inAppUpdate.completeFlexibleUpdate();
  }
}
```

## ⚙️ Platform Setup

### Android Setup

1. **Minimum SDK**: `minSdkVersion 21` in `android/app/build.gradle`
2. **Permissions** in `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
```
3. **FileProvider** for direct APK installation:
```xml
<provider
    android:name="androidx.core.content.FileProvider"
    android:authorities="${applicationId}.fileprovider"
    android:exported="false"
    android:grantUriPermissions="true">
    <meta-data
        android:name="android.support.FILE_PROVIDER_PATHS"
        android:resource="@xml/file_paths" />
</provider>
```

Create `android/app/src/main/res/xml/file_paths.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<paths xmlns:android="http://schemas.android.com/apk/res/android">
    <external-files-path name="external_files" path="." />
</paths>
```

### iOS Setup

1. **Minimum iOS**: Set deployment target to 12.0 or higher in `ios/Podfile`
2. **App Store Updates**: Ensure app is published on App Store Connect
3. **Enterprise/Ad-hoc**: Use proper provisioning profiles and certificates

## 🎯 v2.0.0 Features

### Server-side Update Configuration

Fetch update settings from your server. The plugin caches the config and merges it with local settings.

```dart
// Initialize with remote config URL
_inAppUpdate.initialize(UpdateConfig(
  useStore: true,
  serverConfigUrl: 'https://your-server.com/api/update-config',
  serverHeaders: {'Authorization': 'Bearer token'},
));

// Or fetch manually
final config = await _inAppUpdate.fetchServerConfig();
if (config != null) {
  print('Force update: ${config.forceUpdate}');
  print('Release notes: ${config.releaseNotes}');
}
```

Server response format:
```json
{
  "forceUpdate": false,
  "minimumVersion": "2.0.0",
  "updatePriority": 4,
  "rolloutPercentage": 50,
  "releaseNotes": "Bug fixes and performance improvements",
  "downloadUrl": "https://your-server.com/app-v2.apk"
}
```

### A/B Testing

Assign users to different update strategies deterministically.

```dart
_inAppUpdate.configureABTest(ABTestConfig(
  experimentId: 'update-strategy-v2',
  variants: {
    'control': UpdateConfig(useStore: true),
    'aggressive': UpdateConfig(useStore: true, forceUpdate: true),
    'silent': UpdateConfig(useStore: true, showProgressDialog: false),
  },
  defaultVariant: 'control',
));
```

### Enhanced Progress Reporting

```dart
_inAppUpdate.setUpdateListener(DefaultUpdateListener(
  onProgressDetail: (DownloadProgress progress) {
    print('Progress: ${progress.progress}%');
    print('Downloaded: ${progress.downloadedSize} / ${progress.totalSize}');
    print('Speed: ${progress.speedText}');
    print('ETA: ${progress.etaText}');
    print('State: ${progress.state}'); // DownloadState enum
  },
));
```

### UI Customization

```dart
final theme = UpdateDialogTheme(
  primaryColor: Colors.deepPurple,
  progressColor: Colors.green,
  iconColor: Colors.deepPurple,
  titleStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  updateButtonText: 'Upgrade Now',
  laterButtonText: 'Maybe Later',
);

UpdateAvailableDialog.show(context, updateInfo, config, theme: theme);
ForceUpdateDialog.show(context, updateInfo, config, theme: theme);
```

Preset themes:
```dart
UpdateDialogConfig.light()
UpdateDialogConfig.dark()
UpdateDialogConfig.branded(primaryColor: Colors.deepPurple)
```

### Analytics Integration

```dart
class MyAnalyticsProvider extends UpdateAnalyticsProvider {
  @override
  void onEvent(UpdateAnalyticsEvent event) {
    FirebaseAnalytics.instance.logEvent(
      name: 'update_${event.type.name}',
      parameters: event.data,
    );
  }
}

_inAppUpdate.initializeWithAnalytics(
  config: UpdateConfig(useStore: true),
  analyticsProviders: [MyAnalyticsProvider()],
);
```

Event types: `checkStart`, `checkComplete`, `downloadStart`, `downloadProgress`, `downloadCompleted`, `installStart`, `installCompleted`, `installFailed`, `cancelled`

### Update Rollback

```dart
// Check if rollback is available
final rollbackInfo = await _inAppUpdate.checkRollbackAvailable();
if (rollbackInfo?.rollbackAvailable == true) {
  print('Can revert to v${rollbackInfo!.previousVersion}');
}

// Rollback to previous version (Android only)
final success = await _inAppUpdate.rollbackToPreviousVersion();
```

### Network-aware Updates

```dart
_inAppUpdate.initialize(UpdateConfig(
  useStore: true,
  networkConfig: NetworkConfig.wifiOnlyPolicy,  // WiFi only
  // networkConfig: NetworkConfig.unrestricted,  // Any network
));
```

### Scheduled Update Checks

```dart
// Start periodic checks (respects checkInterval from config)
_inAppUpdate.startScheduledChecks();

// Custom interval
_inAppUpdate.startScheduledChecks(interval: Duration(hours: 6));

// Stop
_inAppUpdate.stopScheduledChecks();
```

### Internationalization

```dart
// Auto-detect from locale
final strings = UpdateStrings.of(context);

// Or use specific language
final strings = UpdateStrings.es();  // Spanish
final strings = UpdateStrings.ja();  // Japanese
```

Built-in languages: English, Spanish, French, German, Japanese, Chinese (Simplified), Korean, Portuguese.

### Update Channels

```dart
_inAppUpdate.initialize(UpdateConfig(
  channel: UpdateChannel.beta,  // stable, beta, canary, internal
));
```

## 📋 API Reference

### InAppUpdateMe Methods

| Method | Description | Since |
|--------|-------------|-------|
| `initialize(UpdateConfig)` | Initialize with configuration | 1.0.0 |
| `initializeWithAnalytics(config:, analyticsProviders:)` | Initialize with analytics | 2.0.0 |
| `checkForUpdate({useStore, updateUrl, currentVersion})` | Check for updates | 1.0.0 |
| `startFlexibleUpdate({downloadUrl})` | Start flexible update | 1.0.0 |
| `startImmediateUpdate()` | Start immediate update | 1.0.0 |
| `completeFlexibleUpdate()` | Complete flexible update | 1.0.0 |
| `downloadAndInstallUpdate(url)` | Download and install directly | 1.0.0 |
| `openStore()` | Open Play Store / App Store | 1.0.0 |
| `performUpdateCheck(UpdateConfig)` | Complete update check | 1.0.0 |
| `fetchServerConfig({forceRefresh})` | Fetch remote config | 2.0.0 |
| `configureABTest(ABTestConfig)` | Set up A/B testing | 2.0.0 |
| `checkRollbackAvailable()` | Check rollback availability | 2.0.0 |
| `rollbackToPreviousVersion()` | Rollback to previous version | 2.0.0 |
| `startScheduledChecks({interval})` | Start periodic checks | 2.0.0 |
| `stopScheduledChecks()` | Stop periodic checks | 2.0.0 |
| `dispose()` | Clean up resources | 2.0.0 |

### Update Listeners

```dart
_inAppUpdate.setUpdateListener(DefaultUpdateListener(
  onProgress: (int progress) { },           // 0-100 percentage
  onProgressDetail: (DownloadProgress p) { }, // Bytes, speed, ETA
  onDownloaded: () { },
  onInstalled: () { },
  onFailed: (String error) { },
  onResult: (String result) { },             // success, cancelled, failed
  onCheckCompleted: (bool available) { },
  onDownloadStarted: () { },                 // iOS background download
  onInstallStarted: () { },                  // iOS install
));
```

### UpdateConfig Options

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `useStore` | `bool` | `true` | Use Play Store / App Store |
| `updateUrl` | `String?` | - | Direct update check URL |
| `forceUpdate` | `bool` | `false` | Make update mandatory |
| `checkInterval` | `Duration` | `24h` | Scheduled check interval |
| `autoCheckOnAppStart` | `bool` | `true` | Auto-check on init |
| `minimumPriority` | `UpdatePriority` | `low` | Minimum priority to show |
| `networkConfig` | `NetworkConfig?` | - | WiFi-only / unrestricted |
| `serverConfigUrl` | `String?` | - | Remote config endpoint |
| `serverHeaders` | `Map?` | - | Headers for config requests |
| `userId` | `String?` | - | User ID for A/B testing |
| `channel` | `UpdateChannel` | `stable` | Update channel |

## 🔧 Custom Update Server

Version check endpoint response format:

```json
{
  "version": "2.0.0",
  "build": 200,
  "priority": 4,
  "forceUpdate": true,
  "updateAvailable": true,
  "downloadUrl": "https://your-server.com/app.apk",
  "releaseNotes": "Critical security update",
  "flexibleUpdateAllowed": true,
  "immediateUpdateAllowed": false
}
```

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Start test server
cd test_server && npm install && npm start

# Run example app
cd example && flutter run
```

See [TESTING_GUIDE.md](TESTING_GUIDE.md) for detailed instructions.

## 📖 Example App

```bash
cd example
flutter run
```

Demonstrates: store updates, direct updates, force update dialogs, progress tracking, release notes, error handling, and all new v2.0.0 features.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📚 Resources

- [Example App](example/) - Full implementation example
- [Testing Guide](TESTING_GUIDE.md) - Testing instructions
- [Test Server](test_server/) - Mock server for development
- [Changelog](CHANGELOG.md) - Version history
