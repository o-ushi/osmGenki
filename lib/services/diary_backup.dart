import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'diary_review_storage.dart';
import 'diary_storage.dart';

/// osmSolverのエクスポート/インポート形式を踏襲した、日記・ダッシュボード・診断結果データの
/// バックアップ（ダッシュボードは日記から算出される表示なので、日記だけで完全に復元できる）。
abstract final class DiaryBackup {
  static const _formatVersion = 1;

  /// 現在保存されている日記件数。
  static Future<int> entryCount() async =>
      (await DiaryStorage.loadAll()).length;

  /// 現在保存されている診断結果（「日記を見てもらう」の貼り付け結果）件数。
  static Future<int> reviewCount() async =>
      (await DiaryReviewStorage.loadAll()).length;

  /// 全エントリー・診断結果をまとめたバックアップJSON文字列を返す。
  static Future<String> buildExportJson() async {
    final entries = await DiaryStorage.loadAll();
    final reviews = await DiaryReviewStorage.loadAll();
    final bundle = {
      'version': _formatVersion,
      'exportDate': DateTime.now().toUtc().toIso8601String(),
      'entries': entries.map((e) => e.toJson()).toList(),
      'reviews': reviews.map((r) => r.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(bundle);
  }

  /// 全エントリーをまとめたバックアップファイルを一時領域に書き出し、そのファイルを返す。
  static Future<File> writeExportFile() async {
    final json = await buildExportJson();
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .substring(0, 15);
    final fileName = 'osmGenki_diary_$stamp.json';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(json, flush: true);
    return file;
  }

  /// バックアップファイルを読み込み、既存の日記・診断結果に追記マージする（置き換えではない）。
  static Future<DiaryImportResult> importFrom(String path) async {
    final content = await File(path).readAsString();
    return importFromContent(content);
  }

  /// バックアップJSON文字列を読み込み、既存の日記・診断結果に追記マージする。
  /// osmSolverの `{version, exportDate, entries:[...]}` 形式（`reviews`は本アプリでの拡張、
  /// 無ければ診断結果は0件として扱う）と、素の配列形式（日記のみ）の両方を受け付ける。
  static Future<DiaryImportResult> importFromContent(String rawContent) async {
    final content = _stripBom(rawContent.trim());
    if (content.isEmpty) {
      throw const FormatException('ファイルが空です');
    }

    final decoded = jsonDecode(content);
    final entryJsonList = _extractList(decoded, 'entries', required: true);
    final reviewJsonList = _extractList(decoded, 'reviews', required: false);
    if (entryJsonList.isEmpty && reviewJsonList.isEmpty) {
      throw const FormatException('日記データが含まれていません');
    }

    final entryResult = await _importEntries(entryJsonList);
    final reviewResult = await _importReviews(reviewJsonList);

    final totalAdded = entryResult.added + reviewResult.added;
    final totalSkipped = entryResult.skipped + reviewResult.skipped;
    final totalInFile = entryResult.totalInFile + reviewResult.totalInFile;
    if (totalAdded == 0 && totalSkipped == 0 && totalInFile > 0) {
      throw const FormatException('ファイル内の日記を読み取れませんでした');
    }

    return DiaryImportResult(
      added: entryResult.added,
      skipped: entryResult.skipped,
      invalid: entryResult.invalid,
      totalInFile: entryResult.totalInFile,
      reviewsAdded: reviewResult.added,
      reviewsSkipped: reviewResult.skipped,
      reviewsInvalid: reviewResult.invalid,
      reviewsTotalInFile: reviewResult.totalInFile,
    );
  }

  static Future<_ImportTally> _importEntries(List<dynamic> jsonList) async {
    final parsed = <DiaryEntry>[];
    var invalid = 0;
    for (final item in jsonList) {
      if (item is! Map) {
        invalid++;
        continue;
      }
      try {
        parsed.add(DiaryEntry.fromJson(Map<String, dynamic>.from(item)));
      } catch (_) {
        invalid++;
      }
    }

    final existing = await DiaryStorage.loadAll();
    final existingKeys = existing.map(_entrySignature).toSet();

    final toAdd = <DiaryEntry>[];
    final pendingKeys = <String>{};
    var skipped = 0;
    for (final entry in parsed) {
      final key = _entrySignature(entry);
      if (existingKeys.contains(key) || pendingKeys.contains(key)) {
        skipped++;
        continue;
      }
      pendingKeys.add(key);
      toAdd.add(entry);
    }

    await DiaryStorage.addAll(toAdd);
    return _ImportTally(
      added: toAdd.length,
      skipped: skipped,
      invalid: invalid,
      totalInFile: jsonList.length,
    );
  }

  static Future<_ImportTally> _importReviews(List<dynamic> jsonList) async {
    final parsed = <DiaryReview>[];
    var invalid = 0;
    for (final item in jsonList) {
      if (item is! Map) {
        invalid++;
        continue;
      }
      try {
        parsed.add(DiaryReview.fromJson(Map<String, dynamic>.from(item)));
      } catch (_) {
        invalid++;
      }
    }

    final existing = await DiaryReviewStorage.loadAll();
    final existingKeys = existing.map(_reviewSignature).toSet();

    final toAdd = <DiaryReview>[];
    final pendingKeys = <String>{};
    var skipped = 0;
    for (final review in parsed) {
      final key = _reviewSignature(review);
      if (existingKeys.contains(key) || pendingKeys.contains(key)) {
        skipped++;
        continue;
      }
      pendingKeys.add(key);
      toAdd.add(review);
    }

    await DiaryReviewStorage.addAll(toAdd);
    return _ImportTally(
      added: toAdd.length,
      skipped: skipped,
      invalid: invalid,
      totalInFile: jsonList.length,
    );
  }

  /// [key]が無い場合、[required]ならエラー、そうでなければ空リストとして扱う。
  static List<dynamic> _extractList(
    Object? decoded,
    String key, {
    required bool required,
  }) {
    if (decoded is Map && decoded.containsKey(key)) {
      final list = decoded[key];
      if (list is List<dynamic>) return list;
      throw FormatException('$key が配列ではありません');
    }
    if (!required) return const [];
    if (decoded is List<dynamic>) return decoded;
    throw const FormatException('認識できないJSON形式です');
  }

  static String _stripBom(String content) {
    if (content.startsWith('\uFEFF')) {
      return content.substring(1);
    }
    return content;
  }

  /// DiaryEntryにIDがないため、日付・元気度・本文の組で重複を判定する。
  static String _entrySignature(DiaryEntry e) =>
      '${e.date.toIso8601String()}|${e.genkiScore}|${e.diaryText}';

  /// DiaryReviewにIDがないため、保存時刻・本文の組で重複を判定する。
  static String _reviewSignature(DiaryReview r) =>
      '${r.date.toIso8601String()}|${r.text}';
}

class _ImportTally {
  const _ImportTally({
    required this.added,
    required this.skipped,
    required this.invalid,
    required this.totalInFile,
  });

  final int added;
  final int skipped;
  final int invalid;
  final int totalInFile;
}

class DiaryImportResult {
  const DiaryImportResult({
    required this.added,
    required this.skipped,
    this.invalid = 0,
    this.totalInFile = 0,
    this.reviewsAdded = 0,
    this.reviewsSkipped = 0,
    this.reviewsInvalid = 0,
    this.reviewsTotalInFile = 0,
  });

  final int added;
  final int skipped;
  final int invalid;
  final int totalInFile;

  /// 診断結果（[DiaryReview]）のインポート集計。ファイルに`reviews`が無ければ全て0。
  final int reviewsAdded;
  final int reviewsSkipped;
  final int reviewsInvalid;
  final int reviewsTotalInFile;
}
