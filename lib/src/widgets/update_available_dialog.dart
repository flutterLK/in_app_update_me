import 'package:flutter/material.dart';
import '../models/update_info.dart';
import '../models/update_config.dart';
import '../in_app_update_me.dart';
import 'update_theme.dart';

class UpdateAvailableDialog extends StatelessWidget {
  final AppUpdateInfo updateInfo;
  final UpdateConfig config;
  final VoidCallback? onUpdateStarted;
  final VoidCallback? onUpdateLater;
  final Function(String)? onError;
  final UpdateDialogTheme? theme;

  const UpdateAvailableDialog({
    Key? key,
    required this.updateInfo,
    required this.config,
    this.onUpdateStarted,
    this.onUpdateLater,
    this.onError,
    this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isHighPriority = updateInfo.isHighPriority;
    final shouldForceUpdate = updateInfo.shouldForceUpdate || config.forceUpdate;
    final primaryColor = theme?.primaryColor ?? (isHighPriority ? Colors.orange : Colors.blue);

    return AlertDialog(
      backgroundColor: theme?.backgroundColor,
      shape: theme?.borderRadius != null
          ? RoundedRectangleBorder(borderRadius: theme!.borderRadius!)
          : null,
      title: theme?.customTitle ??
          Row(
            children: [
              Icon(
                theme?.updateIcon ?? (isHighPriority ? Icons.priority_high : Icons.system_update),
                color: theme?.iconColor ?? primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                theme?.titleText ?? (shouldForceUpdate ? 'Update Required' : 'Update Available'),
                style: theme?.titleStyle,
              ),
            ],
          ),
      content: theme?.customContentBuilder?.call(context, updateInfo) ??
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                theme?.descriptionText ??
                    (shouldForceUpdate
                        ? 'A critical update is available and required to continue using this app.'
                        : 'A new version of this app is available.'),
                style: theme?.bodyStyle ?? const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              if (updateInfo.appStoreVersion != null) ...[
                _buildVersionInfo(),
                const SizedBox(height: 16),
              ],
              if (updateInfo.updatePriority != null) ...[
                _buildPriorityInfo(),
                const SizedBox(height: 16),
              ],
              if (isHighPriority)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This is a high priority update with important improvements.',
                          style: TextStyle(fontSize: 12, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              if (updateInfo.releaseNotes != null && updateInfo.releaseNotes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildReleaseNotes(),
              ],
            ],
          ),
      actions: [
        if (!shouldForceUpdate) ...[
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onUpdateLater?.call();
            },
            style: theme?.laterButtonStyle,
            child: Text(theme?.laterButtonText ?? 'Later'),
          ),
          if (updateInfo.flexibleUpdateAllowed)
            TextButton(
              onPressed: () => _startFlexibleUpdate(context),
              child: const Text('Update in Background'),
            ),
        ],
        ElevatedButton(
          onPressed: () => _startUpdate(context),
          style: theme?.updateButtonStyle ??
              ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
          child: Text(theme?.updateButtonText ?? (shouldForceUpdate ? 'Update Now' : 'Update')),
        ),
      ],
    );
  }

  Widget _buildVersionInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Current Version: ${updateInfo.currentVersion ?? 'Unknown'}'),
        Text('New Version: ${updateInfo.appStoreVersion}'),
      ],
    );
  }

  Widget _buildPriorityInfo() {
    String priorityText;
    Color priorityColor;
    IconData priorityIcon;

    switch (updateInfo.updatePriority) {
      case 5:
        priorityText = 'Critical';
        priorityColor = Colors.red;
        priorityIcon = Icons.error;
        break;
      case 4:
        priorityText = 'High';
        priorityColor = Colors.orange;
        priorityIcon = Icons.priority_high;
        break;
      case 3:
        priorityText = 'Medium';
        priorityColor = Colors.blue;
        priorityIcon = Icons.info;
        break;
      default:
        priorityText = 'Low';
        priorityColor = Colors.green;
        priorityIcon = Icons.info_outline;
    }

    return Row(
      children: [
        Icon(priorityIcon, color: priorityColor, size: 16),
        const SizedBox(width: 4),
        Text(
          'Priority: $priorityText',
          style: TextStyle(color: priorityColor, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildReleaseNotes() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "What's New",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            updateInfo.releaseNotes!,
            style: const TextStyle(fontSize: 13),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _startUpdate(BuildContext context) async {
    Navigator.pop(context);
    onUpdateStarted?.call();

    try {
      bool success = false;

      if (config.useStore) {
        if (updateInfo.immediateUpdateAllowed) {
          success = await InAppUpdateMe().startImmediateUpdate();
        } else {
          success = await InAppUpdateMe().openStore();
        }
      } else if (updateInfo.downloadUrl != null) {
        success = await InAppUpdateMe().downloadAndInstallUpdate(
          updateInfo.downloadUrl!,
        );
      }

      if (!success) {
        onError?.call('Failed to start update');
      }
    } catch (e) {
      onError?.call(e.toString());
    }
  }

  Future<void> _startFlexibleUpdate(BuildContext context) async {
    Navigator.pop(context);
    onUpdateStarted?.call();

    try {
      final success = await InAppUpdateMe().startFlexibleUpdate();
      if (!success) {
        onError?.call('Failed to start flexible update');
      }
    } catch (e) {
      onError?.call(e.toString());
    }
  }

  static Future<void> show(
    BuildContext context,
    AppUpdateInfo updateInfo,
    UpdateConfig config, {
    VoidCallback? onUpdateStarted,
    VoidCallback? onUpdateLater,
    Function(String)? onError,
    UpdateDialogTheme? theme,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: !updateInfo.shouldForceUpdate && !config.forceUpdate,
      builder: (context) => UpdateAvailableDialog(
        updateInfo: updateInfo,
        config: config,
        onUpdateStarted: onUpdateStarted,
        onUpdateLater: onUpdateLater,
        onError: onError,
        theme: theme,
      ),
    );
  }
}
