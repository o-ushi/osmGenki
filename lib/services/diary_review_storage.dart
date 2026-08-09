import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 「日記を見てもらう」（診断）でChrome AIから貼り付けたアドバイス1件分。
/// [DiaryEntry]と違い数値は持たず、読み物としての本文をそのまま保存する。
class DiaryReview {
  const DiaryReview({required this.date, required this.text});

  /// 貼り付けて保存した時刻。
  final DateTime date;

  /// Chrome AIから貼り付けたアドバイス本文（未加工）。
  final String text;

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'text': text,
  };

  factory DiaryReview.fromJson(Map<String, dynamic> json) {
    final dateRaw = json['date'];
    if (dateRaw is! String) {
      throw const FormatException('missing date');
    }
    final textRaw = json['text'];
    if (textRaw is! String) {
      throw const FormatException('missing text');
    }
    return DiaryReview(date: DateTime.parse(dateRaw), text: textRaw);
  }
}

/// 「診断」結果（[DiaryReview]）を端末内のJSONファイルに保存する、[DiaryStorage]と
/// 同じ方式のシンプルなローカルストレージ。
abstract final class DiaryReviewStorage {
  static const _fileName = 'osmgenki_diary_reviews.json';

  /// 保存が起きるたびに値をインクリメントする。閲覧一覧画面はこれを監視して再読込する。
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _fileName));
  }

  static Future<List<DiaryReview>> loadAll() async {
    final file = await _file();
    if (!await file.exists()) return [];

    final content = await file.readAsString();
    if (content.trim().isEmpty) return [];

    final list = jsonDecode(content) as List<dynamic>;
    final reviews = list
        .map((e) => DiaryReview.fromJson(e as Map<String, dynamic>))
        .toList();
    reviews.sort((a, b) => b.date.compareTo(a.date));
    return reviews;
  }

  static Future<void> add(DiaryReview review) async {
    final reviews = await loadAll();
    reviews.insert(0, review);
    await _writeAll(reviews);
  }

  /// インポート用、複数件をまとめて追加する（書き込み・通知は1回だけ）。
  static Future<void> addAll(List<DiaryReview> newReviews) async {
    if (newReviews.isEmpty) return;
    final reviews = await loadAll();
    reviews.insertAll(0, newReviews);
    await _writeAll(reviews);
  }

  /// 1件だけ削除する。[DiaryReview]には一意なIDが無いため、保存時刻（マイクロ秒精度）
  /// が一致するものを削除対象とみなす（[DiaryStorage.remove]と同じ方式）。
  static Future<void> remove(DiaryReview review) async {
    final reviews = await loadAll();
    reviews.removeWhere((r) => r.date.isAtSameMomentAs(review.date));
    await _writeAll(reviews);
  }

  static Future<void> _writeAll(List<DiaryReview> reviews) async {
    final file = await _file();
    await file.writeAsString(
      jsonEncode(reviews.map((r) => r.toJson()).toList()),
    );
    changes.value++;
  }

  static Future<void> clearAll() async {
    final file = await _file();
    await file.writeAsString('[]');
    changes.value++;
  }
}
