import 'package:flutter/material.dart';

/// Configuration for customizing update dialog appearance.
class UpdateDialogConfig {
  /// Title text style.
  final TextStyle? titleStyle;

  /// Message/body text style.
  final TextStyle? messageStyle;

  /// Primary action button style.
  final ButtonStyle? primaryButtonStyle;

  /// Secondary action button style (e.g., "Later").
  final ButtonStyle? secondaryButtonStyle;

  /// Progress indicator color.
  final Color? progressColor;

  /// Background color of the dialog.
  final Color? backgroundColor;

  /// Dialog border radius.
  final double? borderRadius;

  /// Icon shown in the dialog title.
  final IconData? icon;

  /// Icon color.
  final Color? iconColor;

  /// Custom title widget (overrides title text and icon).
  final Widget? customTitle;

  /// Custom message widget (overrides message text).
  final Widget? customMessage;

  /// Custom progress indicator builder.
  final Widget Function(int progress, String message)? customProgressBuilder;

  /// Custom primary button builder.
  final Widget Function(VoidCallback onPressed, String label)? customButtonBuilder;

  /// Whether to show release notes.
  final bool showReleaseNotes;

  /// Maximum lines for release notes before scrolling.
  final int releaseNotesMaxLines;

  const UpdateDialogConfig({
    this.titleStyle,
    this.messageStyle,
    this.primaryButtonStyle,
    this.secondaryButtonStyle,
    this.progressColor,
    this.backgroundColor,
    this.borderRadius,
    this.icon,
    this.iconColor,
    this.customTitle,
    this.customMessage,
    this.customProgressBuilder,
    this.customButtonBuilder,
    this.showReleaseNotes = true,
    this.releaseNotesMaxLines = 5,
  });

  /// Light theme preset.
  factory UpdateDialogConfig.light() => const UpdateDialogConfig(
    progressColor: Colors.blue,
    iconColor: Colors.blue,
  );

  /// Dark theme preset.
  factory UpdateDialogConfig.dark() => UpdateDialogConfig(
    backgroundColor: const Color(0xFF1E1E1E),
    titleStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
    messageStyle: const TextStyle(color: Colors.white70, fontSize: 14),
    progressColor: Colors.blueAccent,
    iconColor: Colors.blueAccent,
  );

  /// Branded preset with custom colors.
  factory UpdateDialogConfig.branded({
    required Color primaryColor,
    Color? backgroundColor,
  }) => UpdateDialogConfig(
    progressColor: primaryColor,
    iconColor: primaryColor,
    backgroundColor: backgroundColor,
    primaryButtonStyle: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
  );
}
