import 'package:flutter/material.dart';
import '../models/download_progress.dart' as dp;
import 'update_theme.dart';

class UpdateProgressDialog extends StatelessWidget {
  final int progress;
  final String message;
  final bool isIndeterminate;
  final VoidCallback? onCancel;
  final dp.DownloadProgress? detailedProgress;
  final UpdateDialogTheme? theme;

  const UpdateProgressDialog({
    Key? key,
    required this.progress,
    required this.message,
    this.isIndeterminate = false,
    this.onCancel,
    this.detailedProgress,
    this.theme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final primaryColor = theme?.progressColor ?? Colors.blue;

    return AlertDialog(
      backgroundColor: theme?.backgroundColor,
      shape: theme?.borderRadius != null
          ? RoundedRectangleBorder(borderRadius: theme!.borderRadius!)
          : null,
      title: Row(
        children: [
          Icon(theme?.updateIcon ?? Icons.download, color: theme?.iconColor ?? primaryColor),
          const SizedBox(width: 8),
          Text(theme?.titleText ?? 'Updating App', style: theme?.titleStyle),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isIndeterminate)
            LinearProgressIndicator(color: primaryColor)
          else
            LinearProgressIndicator(
              value: progress / 100,
              color: primaryColor,
            ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme?.bodyStyle ?? const TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          if (!isIndeterminate) ...[
            const SizedBox(height: 8),
            Text(
              '$progress%',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
          if (detailedProgress != null) ...[
            const SizedBox(height: 12),
            _buildDetailedInfo(detailedProgress!),
          ],
        ],
      ),
      actions: [
        if (onCancel != null)
          TextButton(
            onPressed: onCancel,
            child: Text(theme?.laterButtonText ?? 'Cancel'),
          ),
      ],
    );
  }

  Widget _buildDetailedInfo(dp.DownloadProgress details) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        children: [
          if (details.isTotalKnown)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Downloaded: ${details.downloadedSize}', style: const TextStyle(fontSize: 12)),
                Text('Total: ${details.totalSize}', style: const TextStyle(fontSize: 12)),
              ],
            ),
          if (details.speedBytesPerSec > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Speed: ${details.speedText}', style: const TextStyle(fontSize: 12)),
                  Text('ETA: ${details.etaText}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static Future<void> show(
    BuildContext context, {
    required int progress,
    required String message,
    bool isIndeterminate = false,
    VoidCallback? onCancel,
    dp.DownloadProgress? detailedProgress,
    UpdateDialogTheme? theme,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => UpdateProgressDialog(
        progress: progress,
        message: message,
        isIndeterminate: isIndeterminate,
        onCancel: onCancel,
        detailedProgress: detailedProgress,
        theme: theme,
      ),
    );
  }
}
