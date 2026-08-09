import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import 'confirm_dialog.dart';

/// 「削除しますか？」の確認ダイアログ。日記一覧・診断結果一覧で共通に使う。
/// [bodyKey]は削除対象を説明する本文の翻訳キー
/// （例: '日記削除_確認' / '診断結果削除_確認'）。
Future<bool> confirmDelete(
  BuildContext context, {
  required String lang,
  required String bodyKey,
}) {
  return showConfirmDialog(
    context,
    title: '削除しますか？'.tr(lang),
    message: bodyKey.tr(lang),
    confirmLabel: '削除'.tr(lang),
    confirmColor: kRecordingColor,
    cancelLabel: 'キャンセル'.tr(lang),
    barrierDismissible: true,
  );
}
