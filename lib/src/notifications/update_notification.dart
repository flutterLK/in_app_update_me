/// Configuration for update completion notifications.
class UpdateNotificationConfig {
  /// Title of the notification.
  final String title;

  /// Body text of the notification.
  final String body;

  /// Notification channel ID (Android).
  final String channelId;

  /// Notification channel name (Android).
  final String channelName;

  /// Small icon resource name (Android).
  final String? icon;

  /// Whether to play a sound.
  final bool playSound;

  /// Whether to vibrate.
  final bool vibrate;

  const UpdateNotificationConfig({
    this.title = 'Update Ready',
    this.body = 'An update has been downloaded and is ready to install.',
    this.channelId = 'in_app_update_me',
    this.channelName = 'App Updates',
    this.icon,
    this.playSound = true,
    this.vibrate = true,
  });
}

/// Callback type for showing update notifications.
typedef ShowNotificationCallback = void Function(UpdateNotificationConfig config);
