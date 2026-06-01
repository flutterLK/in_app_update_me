# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Server-side update configuration
- A/B testing support for updates
- Update rollback functionality
- Enhanced progress reporting
- Additional UI customization options
- Analytics integration

## [1.2.0] - 2026-06-01

### Fixed
- **Duplicate class definitions**: Moved `UpdateInfo` and `UpdateListener` to `lib/src/` as canonical sources; platform interface now re-exports from there
- **Android `build.gradle`**: Removed `buildscript` and `rootProject.allprojects` blocks that conflict with consuming apps
- **Direct update ignoring server response** (Android + iOS): Both platforms now parse the JSON response body from the update server instead of returning hardcoded values
- **`initialize()` ignoring config**: Plugin now stores and exposes the `UpdateConfig` passed to `initialize()`
- **iOS `redirectToAppStore` URL format**: Now uses iTunes Lookup API to get `trackId` for proper App Store URLs instead of using `bundleId` in the URL
- **`openStore()` hardcoded iOS URL**: Now uses iTunes Lookup API to dynamically resolve the correct App Store URL
- **Coroutine scope leak** (Android): Replaced unmanaged `CoroutineScope(Dispatchers.IO)` with a structured `pluginScope` using `SupervisorJob` that is cancelled on detach
- **`FileOutputStream` not closed** (Android): Wrapped file streams in Kotlin `use { }` blocks for proper resource cleanup
- **CHANGELOG order**: Reordered entries with newest at top
- **iOS `detachFromEngine`**: Added proper cleanup of `URLSession` and method channel on plugin detach
- **`ForceUpdateDialog` overwriting listener**: Dialog now saves the user's listener on init and restores it on dispose
- **`shouldForceUpdate` semantics**: Now considers server-declared `forceUpdate` flag in addition to high priority + immediate allowed

### Changed
- Removed all Flenco branding; package namespace updated to `com.inappupdateme.plugin`
- Updated Android compileSdkVersion to 35, Kotlin/Java target to 17
- Updated iOS minimum platform to 12.0
- Updated all dependency versions to latest
- Updated repository URLs to flutterLK organization
- Removed `INSTALL_PACKAGES` permission (system-only) from Android manifest
- Removed unused `WRITE_EXTERNAL_STORAGE` permission from Android manifest

## [1.1.1] - 2025-09-05

### Fixed
- Swift compiler error: Fixed "Invalid redeclaration of 'isFlexibleUpdateDownloading()'" by renaming function to `checkFlexibleUpdateDownloading()`
- Resolved naming conflict between property and method in iOS Swift implementation

## [1.1.0] - 2025-09-05

### Added
- iOS flexible updates support for enterprise and ad-hoc distributed apps
- Background download support with progress tracking via URLSessionDownloadDelegate
- New listener events: `onUpdateDownloadStarted()`, `onUpdateInstallStarted()`
- `startFlexibleUpdate()` now accepts optional `downloadUrl` parameter for iOS

## [1.0.2] - 2025-09-05

### Changed
- Android package/namespace updated

## [1.0.1] - 2025-09-05

### Fixed
- Add Android Gradle namespace to `android/build.gradle` to satisfy AGP 7.3+/8+

## [1.0.0] - 2024-01-15

### Added
- Initial release of in_app_update_me plugin
- Cross-platform support for Android and iOS
- Google Play In-App Updates API integration (immediate and flexible)
- App Store version checking via iTunes API
- Direct APK download and installation support
- Force update functionality with blocking UI
- Real-time download progress tracking
- Pre-built UI widgets (ForceUpdateDialog, UpdateAvailableDialog, UpdateProgressDialog)
- Update priority handling
- Custom update listeners
- Background update support
- Enterprise app distribution support
