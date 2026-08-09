import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_strings.dart';
import '../app_globals.dart';
import 'diary_backup.dart';

/// 設定画面・メイン画面の「...」メニューの両方から呼び出す、日記・診断結果のエクスポート/
/// インポート処理。osmSolverのエクスポート機能を踏襲: 全件をJSONにまとめて共有シートで書き出す。
Future<void> exportDiary(BuildContext context) async {
  final lang = appSettings.language;
  try {
    final count = await DiaryBackup.entryCount();
    final reviewCount = await DiaryBackup.reviewCount();
    if (count == 0 && reviewCount == 0) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('エクスポートする日記がありません'.tr(lang))));
      return;
    }

    final file = await DiaryBackup.writeExportFile();
    if (!context.mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    final fileName = file.uri.pathSegments.last;
    final text = reviewCount > 0
        ? '日記をエクスポートしました_件数_診断結果あり'.trFmt(lang, ['$count', '$reviewCount'])
        : '日記をエクスポートしました_件数'.trFmt(lang, ['$count']);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json', name: fileName)],
        subject: '日記をエクスポート'.tr(lang),
        text: text,
        sharePositionOrigin: origin,
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('エクスポートに失敗しました'.tr(lang))));
  }
}

/// osmSolverのインポート機能を踏襲: ファイル選択 → 解析 → 既存データに追記マージ。
/// 重複（日記は日付・元気度・本文、診断結果は保存時刻・本文が完全一致）はスキップし、
/// 置き換えではなく追加する。
Future<void> importDiary(BuildContext context) async {
  final lang = appSettings.language;
  const jsonType = XTypeGroup(
    label: 'JSON',
    extensions: ['json'],
    mimeTypes: ['application/json'],
    uniformTypeIdentifiers: ['public.json'],
  );
  final file = await openFile(acceptedTypeGroups: [jsonType]);
  if (file == null || !context.mounted) return;

  try {
    final content = await file.readAsString();
    final result = await DiaryBackup.importFromContent(content);
    if (!context.mounted) return;

    final message = _buildImportMessage(result, lang);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('インポート完了'.tr(lang)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('OK'.tr(lang)),
          ),
        ],
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('インポートエラー'.tr(lang)),
        content: Text('インポート失敗_メッセージ'.trFmt(lang, ['$e'])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('OK'.tr(lang)),
          ),
        ],
      ),
    );
  }
}

/// 日記の集計メッセージに、ファイルに診断結果が含まれていた場合だけその集計を続けて表示する。
String _buildImportMessage(DiaryImportResult result, String lang) {
  final String? entryMessage;
  if (result.totalInFile == 0) {
    entryMessage = null;
  } else if (result.added == 0 && result.skipped > 0) {
    entryMessage = '日記をインポートしました_すべてスキップ'.trFmt(lang, ['${result.skipped}']);
  } else {
    entryMessage = result.skipped > 0
        ? '日記をインポートしました_スキップあり'.trFmt(lang, [
            '${result.added}',
            '${result.skipped}',
          ])
        : '日記をインポートしました'.trFmt(lang, ['${result.added}']);
  }

  final String? reviewMessage;
  if (result.reviewsTotalInFile == 0) {
    reviewMessage = null;
  } else if (result.reviewsAdded == 0 && result.reviewsSkipped > 0) {
    reviewMessage = '診断結果をインポートしました_すべてスキップ'.trFmt(lang, [
      '${result.reviewsSkipped}',
    ]);
  } else {
    reviewMessage = result.reviewsSkipped > 0
        ? '診断結果をインポートしました_スキップあり'.trFmt(lang, [
            '${result.reviewsAdded}',
            '${result.reviewsSkipped}',
          ])
        : '診断結果をインポートしました'.trFmt(lang, ['${result.reviewsAdded}']);
  }

  return [entryMessage, reviewMessage].whereType<String>().join('\n');
}
