import 'package:flutter/material.dart';

/// Localized strings for update dialogs.
class UpdateStrings {
  final String updateAvailableTitle;
  final String updateRequiredTitle;
  final String updateAvailableMessage;
  final String updateRequiredMessage;
  final String currentVersionLabel;
  final String newVersionLabel;
  final String priorityLabel;
  final String priorityCritical;
  final String priorityHigh;
  final String priorityMedium;
  final String priorityLow;
  final String highPriorityWarning;
  final String laterButton;
  final String updateButton;
  final String updateNowButton;
  final String exitAppButton;
  final String updateInBackgroundButton;
  final String downloadingMessage;
  final String downloadCompleteMessage;
  final String installingMessage;
  final String installCompleteMessage;
  final String updateFailedMessage;
  final String cancelButton;
  final String updatingTitle;
  final String releaseNotesTitle;
  final String rollbackButton;
  final String rollbackConfirmTitle;
  final String rollbackConfirmMessage;
  final String confirmButton;
  final String maintenanceModeMessage;

  const UpdateStrings({
    this.updateAvailableTitle = 'Update Available',
    this.updateRequiredTitle = 'Update Required',
    this.updateAvailableMessage = 'A new version of this app is available.',
    this.updateRequiredMessage = 'A new version of this app is available and required to continue.',
    this.currentVersionLabel = 'Current Version',
    this.newVersionLabel = 'New Version',
    this.priorityLabel = 'Priority',
    this.priorityCritical = 'Critical',
    this.priorityHigh = 'High',
    this.priorityMedium = 'Medium',
    this.priorityLow = 'Low',
    this.highPriorityWarning = 'This is a high priority update with important improvements.',
    this.laterButton = 'Later',
    this.updateButton = 'Update',
    this.updateNowButton = 'Update Now',
    this.exitAppButton = 'Exit App',
    this.updateInBackgroundButton = 'Update in Background',
    this.downloadingMessage = 'Downloading update...',
    this.downloadCompleteMessage = 'Download completed. Installing...',
    this.installingMessage = 'Installing update...',
    this.installCompleteMessage = 'Update installed successfully!',
    this.updateFailedMessage = 'Update failed',
    this.cancelButton = 'Cancel',
    this.updatingTitle = 'Updating App',
    this.releaseNotesTitle = "What's New",
    this.rollbackButton = 'Revert to Previous Version',
    this.rollbackConfirmTitle = 'Confirm Rollback',
    this.rollbackConfirmMessage = 'Are you sure you want to revert to the previous version?',
    this.confirmButton = 'Confirm',
    this.maintenanceModeMessage = 'The app is currently under maintenance. Please try again later.',
  });

  /// Get the appropriate strings for the current locale.
  static UpdateStrings of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    switch (locale.languageCode) {
      case 'es': return const UpdateStrings(
        updateAvailableTitle: 'Actualizacion Disponible',
        updateRequiredTitle: 'Actualizacion Requerida',
        updateAvailableMessage: 'Una nueva version de esta aplicacion esta disponible.',
        updateRequiredMessage: 'Una nueva version esta disponible y es necesaria para continuar.',
        currentVersionLabel: 'Version Actual',
        newVersionLabel: 'Nueva Version',
        laterButton: 'Despues',
        updateButton: 'Actualizar',
        updateNowButton: 'Actualizar Ahora',
        exitAppButton: 'Salir',
        updateInBackgroundButton: 'Actualizar en Segundo Plano',
        downloadingMessage: 'Descargando actualizacion...',
        cancelButton: 'Cancelar',
        updatingTitle: 'Actualizando App',
      );
      case 'fr': return const UpdateStrings(
        updateAvailableTitle: 'Mise a Jour Disponible',
        updateRequiredTitle: 'Mise a Jour Requise',
        updateAvailableMessage: 'Une nouvelle version de cette application est disponible.',
        updateRequiredMessage: 'Une nouvelle version est disponible et requise pour continuer.',
        currentVersionLabel: 'Version Actuelle',
        newVersionLabel: 'Nouvelle Version',
        laterButton: 'Plus Tard',
        updateButton: 'Mettre a Jour',
        updateNowButton: 'Mettre a Jour Maintenant',
        exitAppButton: 'Quitter',
        updateInBackgroundButton: 'Mettre a Jour en Arriere-Plan',
        downloadingMessage: 'Telechargement de la mise a jour...',
        cancelButton: 'Annuler',
        updatingTitle: 'Mise a Jour',
      );
      case 'de': return const UpdateStrings(
        updateAvailableTitle: 'Update Verfugbar',
        updateRequiredTitle: 'Update Erforderlich',
        laterButton: 'Spater',
        updateButton: 'Aktualisieren',
        updateNowButton: 'Jetzt Aktualisieren',
        exitAppButton: 'Beenden',
        cancelButton: 'Abbrechen',
      );
      case 'ja': return const UpdateStrings(
        updateAvailableTitle: 'アップデートがあります',
        updateRequiredTitle: 'アップデートが必要です',
        updateAvailableMessage: '新しいバージョンが利用可能です。',
        updateRequiredMessage: '新しいバージョンが利用可能で、続行するには必要です。',
        laterButton: '後で',
        updateButton: 'アップデート',
        updateNowButton: '今すぐアップデート',
        exitAppButton: '終了',
        cancelButton: 'キャンセル',
      );
      case 'zh': return const UpdateStrings(
        updateAvailableTitle: '有可用更新',
        updateRequiredTitle: '需要更新',
        updateAvailableMessage: '此应用有新版本可用。',
        updateRequiredMessage: '有新版本可用，需要更新才能继续使用。',
        laterButton: '稍后',
        updateButton: '更新',
        updateNowButton: '立即更新',
        exitAppButton: '退出',
        cancelButton: '取消',
      );
      case 'ko': return const UpdateStrings(
        updateAvailableTitle: '업데이트 가능',
        updateRequiredTitle: '업데이트 필요',
        laterButton: '나중에',
        updateButton: '업데이트',
        updateNowButton: '지금 업데이트',
        exitAppButton: '종료',
        cancelButton: '취소',
      );
      case 'pt': return const UpdateStrings(
        updateAvailableTitle: 'Atualizacao Disponivel',
        updateRequiredTitle: 'Atualizacao Necessaria',
        laterButton: 'Depois',
        updateButton: 'Atualizar',
        updateNowButton: 'Atualizar Agora',
        exitAppButton: 'Sair',
        cancelButton: 'Cancelar',
      );
      default: return const UpdateStrings();
    }
  }

  /// Get priority label for a given priority value.
  String getPriorityText(int? priority) {
    switch (priority) {
      case 5: return priorityCritical;
      case 4: return priorityHigh;
      case 3: return priorityMedium;
      default: return priorityLow;
    }
  }
}
