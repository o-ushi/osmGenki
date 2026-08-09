import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

/// 発話解析・日記傾向診断など、Google検索（AIモード）へ送信する前に都度表示する
/// 同意確認ダイアログ（何を・誰に送るかを開示した上で許可を取る）。
/// [titleKey]/[bodyKey]は送信内容ごとの翻訳キー
/// （例: 'Google送信確認_タイトル_発言'/'Google送信確認_本文_発言'）。
Future<bool> confirmSendToGoogleAi(
  BuildContext context, {
  required String lang,
  required String titleKey,
  required String bodyKey,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(titleKey.tr(lang)),
      content: Text(bodyKey.tr(lang)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text('キャンセル'.tr(lang)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text('送信'.tr(lang)),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
