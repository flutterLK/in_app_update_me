import 'package:flutter/material.dart';
import '../models/update_info.dart';

/// Theme configuration for update dialogs.
class UpdateDialogTheme {
  final Color? primaryColor;
  final Color? backgroundColor;
  final Color? progressColor;
  final Color? iconColor;
  final TextStyle? titleStyle;
  final TextStyle? bodyStyle;
  final TextStyle? versionStyle;
  final ButtonStyle? updateButtonStyle;
  final ButtonStyle? laterButtonStyle;
  final IconData? updateIcon;
  final String? updateButtonText;
  final String? laterButtonText;
  final String? titleText;
  final String? descriptionText;
  final BorderRadius? borderRadius;
  final EdgeInsets? contentPadding;
  final Widget? customTitle;
  final Widget? customContent;
  final Widget Function(BuildContext, AppUpdateInfo)? customHeaderBuilder;
  final Widget Function(BuildContext, AppUpdateInfo)? customContentBuilder;

  const UpdateDialogTheme({
    this.primaryColor,
    this.backgroundColor,
    this.progressColor,
    this.iconColor,
    this.titleStyle,
    this.bodyStyle,
    this.versionStyle,
    this.updateButtonStyle,
    this.laterButtonStyle,
    this.updateIcon,
    this.updateButtonText,
    this.laterButtonText,
    this.titleText,
    this.descriptionText,
    this.borderRadius,
    this.contentPadding,
    this.customTitle,
    this.customContent,
    this.customHeaderBuilder,
    this.customContentBuilder,
  });

  UpdateDialogTheme copyWith({
    Color? primaryColor,
    Color? backgroundColor,
    Color? progressColor,
    Color? iconColor,
    TextStyle? titleStyle,
    TextStyle? bodyStyle,
    TextStyle? versionStyle,
    ButtonStyle? updateButtonStyle,
    ButtonStyle? laterButtonStyle,
    IconData? updateIcon,
    String? updateButtonText,
    String? laterButtonText,
    String? titleText,
    String? descriptionText,
    BorderRadius? borderRadius,
    EdgeInsets? contentPadding,
  }) {
    return UpdateDialogTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      progressColor: progressColor ?? this.progressColor,
      iconColor: iconColor ?? this.iconColor,
      titleStyle: titleStyle ?? this.titleStyle,
      bodyStyle: bodyStyle ?? this.bodyStyle,
      versionStyle: versionStyle ?? this.versionStyle,
      updateButtonStyle: updateButtonStyle ?? this.updateButtonStyle,
      laterButtonStyle: laterButtonStyle ?? this.laterButtonStyle,
      updateIcon: updateIcon ?? this.updateIcon,
      updateButtonText: updateButtonText ?? this.updateButtonText,
      laterButtonText: laterButtonText ?? this.laterButtonText,
      titleText: titleText ?? this.titleText,
      descriptionText: descriptionText ?? this.descriptionText,
      borderRadius: borderRadius ?? this.borderRadius,
      contentPadding: contentPadding ?? this.contentPadding,
      customHeaderBuilder: customHeaderBuilder ?? this.customHeaderBuilder,
      customContentBuilder: customContentBuilder ?? this.customContentBuilder,
    );
  }
}
