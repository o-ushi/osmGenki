import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

/// 「日記を見てもらう」（診断）でChrome AIから貰ったアドバイス本文を表示するダイアログ。
/// 貼り付け直後（[date]省略）と、閲覧一覧からの再表示（[date]あり）の両方で使う。
Future<void> showDiaryReviewDialog({
  required BuildContext context,
  required String lang,
  required String text,
  DateTime? date,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        date == null
            ? 'アドバイス'.tr(lang)
            : '${'アドバイス'.tr(lang)}（${AppStrings.dateLabel(date, lang)}）',
      ),
      content: SingleChildScrollView(
        child: Text(text, style: const TextStyle(height: 1.5)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text('OK'.tr(lang)),
        ),
      ],
    ),
  );
}
