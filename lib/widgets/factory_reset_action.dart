import 'package:flutter/material.dart';

import '../app_globals.dart';
import '../l10n/app_strings.dart';
import '../services/app_reset.dart';
import '../theme/app_colors.dart';
import 'confirm_dialog.dart';

/// 「初期化」の確認ダイアログ表示から [AppReset.resetToFactoryDefaults] 実行、
/// 設定の再読込、完了スナックバー表示までを行う。設定画面とプライバシー画面の
/// 両方から同じ導線として呼び出す。
Future<void> confirmFactoryReset(BuildContext context) async {
  final lang = appSettings.language;
  final confirmed = await showConfirmDialog(
    context,
    title: '初期化しますか？'.tr(lang),
    message: '初期化_確認'.tr(lang),
    confirmLabel: '初期化'.tr(lang),
    confirmColor: kRecordingColor,
    cancelLabel: 'キャンセル'.tr(lang),
  );
  if (!confirmed || !context.mounted) return;

  await AppReset.resetToFactoryDefaults();
  if (!context.mounted) return;
  // プリファレンスを直接クリアしたので、appSettingsに既定値（言語はベトナム語）を
  // 読み直させてから再描画する。
  appSettings.refresh();
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text('初期化しました'.tr(appSettings.language))));
}
