import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/update_info.dart';
import '../in_app_update_me.dart';
import '../models/update_config.dart';
import '../listeners/update_listener.dart';
import 'update_theme.dart';

class ForceUpdateDialog extends StatefulWidget {
  final AppUpdateInfo updateInfo;
  final UpdateConfig config;
  final VoidCallback? onUpdateStarted;
  final Function(String)? onError;
  final bool dismissible;
  final UpdateDialogTheme? theme;

  const ForceUpdateDialog({
    Key? key,
    required this.updateInfo,
    required this.config,
    this.onUpdateStarted,
    this.onError,
    this.dismissible = false,
    this.theme,
  }) : super(key: key);

  @override
  State<ForceUpdateDialog> createState() => _ForceUpdateDialogState();

  static Future<void> show(
    BuildContext context,
    AppUpdateInfo updateInfo,
    UpdateConfig config, {
    VoidCallback? onUpdateStarted,
    Function(String)? onError,
    UpdateDialogTheme? theme,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: ForceUpdateDialog(
          updateInfo: updateInfo,
          config: config,
          onUpdateStarted: onUpdateStarted,
          onError: onError,
          dismissible: false,
          theme: theme,
        ),
      ),
    );
  }
}

class _ForceUpdateDialogState extends State<ForceUpdateDialog> {
  bool _isUpdating = false;
  int _downloadProgress = 0;
  String _statusMessage = '';
  DefaultUpdateListener? _previousListener;

  @override
  void initState() {
    super.initState();
    _previousListener = InAppUpdateMe().updateListener;
    _setupUpdateListener();
  }

  @override
  void dispose() {
    if (_previousListener != null) {
      InAppUpdateMe().setUpdateListener(_previousListener!);
    }
    super.dispose();
  }

  void _setupUpdateListener() {
    InAppUpdateMe().setUpdateListener(DefaultUpdateListener(
      onProgress: (progress) {
        if (!mounted) return;
        setState(() {
          _downloadProgress = progress;
          _statusMessage = 'Downloading... $progress%';
        });
      },
      onDownloaded: () {
        if (!mounted) return;
        setState(() {
          _statusMessage = 'Download completed. Installing...';
        });
      },
      onInstalled: () {
        if (!mounted) return;
        setState(() {
          _statusMessage = 'Update installed successfully!';
        });
      },
      onFailed: (error) {
        if (!mounted) return;
        setState(() {
          _isUpdating = false;
          _statusMessage = 'Update failed: $error';
        });
        widget.onError?.call(error);
      },
      onResult: (result) {
        if (result == 'cancelled') {
          _startUpdate();
        }
      },
    ));
  }

  Future<void> _startUpdate() async {
    setState(() {
      _isUpdating = true;
      _statusMessage = 'Starting update...';
    });

    widget.onUpdateStarted?.call();

    try {
      bool success = false;

      if (widget.config.useStore) {
        if (widget.updateInfo.immediateUpdateAllowed) {
          success = await InAppUpdateMe().startImmediateUpdate();
        } else {
          success = await InAppUpdateMe().openStore();
        }
      } else if (widget.updateInfo.downloadUrl != null) {
        success = await InAppUpdateMe().downloadAndInstallUpdate(
          widget.updateInfo.downloadUrl!,
        );
      }

      if (!success && mounted) {
        setState(() {
          _isUpdating = false;
          _statusMessage = 'Failed to start update';
        });
        widget.onError?.call('Failed to start update');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
          _statusMessage = 'Update error: $e';
        });
        widget.onError?.call(e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final primaryColor = theme?.primaryColor ?? Colors.red;

    return AlertDialog(
      backgroundColor: theme?.backgroundColor,
      shape: theme?.borderRadius != null
          ? RoundedRectangleBorder(borderRadius: theme!.borderRadius!)
          : null,
      title: theme?.customTitle ??
          Row(
            children: [
              Icon(theme?.updateIcon ?? Icons.system_update, color: theme?.iconColor ?? primaryColor),
              const SizedBox(width: 8),
              Text(
                theme?.titleText ?? 'Update Required',
                style: theme?.titleStyle,
              ),
            ],
          ),
      content: theme?.customContentBuilder?.call(context, widget.updateInfo) ??
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                theme?.descriptionText ?? 'A new version of this app is available and required to continue.',
                style: theme?.bodyStyle ?? const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              if (widget.updateInfo.appStoreVersion != null) ...[
                Text('Current Version: ${widget.updateInfo.currentVersion ?? 'Unknown'}'),
                Text('New Version: ${widget.updateInfo.appStoreVersion}'),
                const SizedBox(height: 16),
              ],
              if (widget.updateInfo.releaseNotes != null && widget.updateInfo.releaseNotes!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("What's New", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 8),
                      Text(widget.updateInfo.releaseNotes!, style: const TextStyle(fontSize: 13), maxLines: 5, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_isUpdating) ...[
                LinearProgressIndicator(
                  value: _downloadProgress > 0 ? _downloadProgress / 100 : null,
                  color: theme?.progressColor ?? primaryColor,
                ),
                const SizedBox(height: 8),
                Text(
                  _statusMessage,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ],
          ),
      actions: [
        if (!_isUpdating) ...[
          TextButton(
            onPressed: widget.dismissible
                ? () => Navigator.pop(context)
                : () => SystemNavigator.pop(),
            style: theme?.laterButtonStyle,
            child: Text(
              theme?.laterButtonText ?? (widget.dismissible ? 'Later' : 'Exit App'),
              style: TextStyle(
                color: widget.dismissible ? Colors.grey : primaryColor,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _startUpdate,
            style: theme?.updateButtonStyle ??
                ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
            child: Text(theme?.updateButtonText ?? 'Update Now'),
          ),
        ] else ...[
          const SizedBox(
            width: 100,
            child: Center(child: Text('Updating...')),
          ),
        ],
      ],
    );
  }
}
