import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/jsst_scoring_models.dart';

/// 日付を年月日単位でグルーピングするためのキー（例: "2026-07-04"）。
/// Prefer [DiaryStorage.dateKeyFor]。
String dateKeyFor(DateTime date) => DiaryStorage.dateKeyFor(date);

class DiaryEntry {
  const DiaryEntry({
    required this.date,
    required this.genkiScore,
    required this.diaryText,
    this.initialMoodScore,
    this.positivity,
    this.stress,
    this.fatigue,
    this.motivation,
    this.japaneseLevel,
    this.summary,
    this.genkiReason,
    this.japaneseReason,
    this.fluencySnapshot,
    this.japaneseLevelRuleBasedBand,
    this.japaneseLevelRuleBased1to4,
    this.recordedAt,
  });

  final DateTime date;
  final int genkiScore;
  final String diaryText;

  /// 気分選択画面（起動直後）で選ばれた元気度の起点（1/3/5/7/9）。
  /// Chrome AIの加減点計算の基準値。
  final int? initialMoodScore;

  /// 元気度の内訳4項目（各0〜4、Chrome AIの判定）。スコア内訳ダイアログ表示用。
  /// 4項目すべて揃っている場合のみ、[GenkiScoreCalculator.adjustmentFromDimensions]
  /// で加減点を計算する。旧エントリ・4項目が取れなかった場合はすべてnull。
  final int? positivity;
  final int? stress;
  final int? fatigue;
  final int? motivation;

  /// JSSTと同じ1〜10スケールの日本語評点。osmWashabeのJSST採点手法（ルールベース）
  /// とChrome AI自身の判定を合成した値（[JsstScoreCombiner]参照）。
  final int? japaneseLevel;

  /// AIが元気度を判定する前に書く、話した内容の1〜2文の要約。Chrome AIの解析結果から
  /// 取れた場合のみ入る。取れなかった旧形式のエントリではnull。
  final String? summary;

  /// 元気度の理由（1行1項目、箇条書きマーカーなし）。Chrome AIの解析結果から取れた
  /// 場合のみ入る。取れなかった旧形式のエントリではnullで、[diaryText]をそのまま表示する。
  final String? genkiReason;

  /// 日本語評点の理由（1行1項目、箇条書きマーカーなし）。[genkiReason]と同様。
  final String? japaneseReason;

  /// 会話力スコア算出時の流暢さ指標（osmWashabeの「時間の使い方」と同項目）。
  /// 旧エントリではnull。
  final FluencySnapshot? fluencySnapshot;

  /// Chrome AIを混ぜない、osmWashabeのルールベース判定そのままの帯域ラベル
  /// （「1〜2」「3〜4」「5〜6」「7〜」、[JsstScoreCombiner.ruleBasedBandLabel]参照）。
  /// スコア内訳ダイアログ表示用。旧エントリではnull。
  final String? japaneseLevelRuleBasedBand;

  /// [japaneseLevelRuleBasedBand]の元になった、アプリ内参照レベル（1〜4、
  /// [JsstScoringService.combinedReferenceLevel]の値そのまま）。
  /// キャリブレーション（開発者向け、[JsstCalibrationService]参照）でのみ使う。旧エントリではnull。
  final int? japaneseLevelRuleBased1to4;

  /// 実際に録音を開始した時刻（[date]は保存時刻のため、Chrome AI貼り付けまでの
  /// 待ち時間ぶんずれることがある）。旧エントリ・録音を伴わない保存ではnull。
  final DateTime? recordedAt;

  String get dateKey => DiaryStorage.dateKeyFor(date);

  /// 録音時刻の24時間表示（例: "14:05"）。[recordedAt]が無ければ[date]の時刻を使う。
  String get recordedTimeLabel {
    final t = recordedAt ?? date;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'genkiScore': genkiScore,
    'diaryText': diaryText,
    if (initialMoodScore != null) 'initialMoodScore': initialMoodScore,
    if (positivity != null) 'positivity': positivity,
    if (stress != null) 'stress': stress,
    if (fatigue != null) 'fatigue': fatigue,
    if (motivation != null) 'motivation': motivation,
    if (japaneseLevel != null) 'japaneseLevel': japaneseLevel,
    if (summary != null) 'summary': summary,
    if (genkiReason != null) 'genkiReason': genkiReason,
    if (japaneseReason != null) 'japaneseReason': japaneseReason,
    if (fluencySnapshot != null) 'fluencySnapshot': fluencySnapshot!.toJson(),
    if (japaneseLevelRuleBasedBand != null)
      'japaneseLevelRuleBasedBand': japaneseLevelRuleBasedBand,
    if (japaneseLevelRuleBased1to4 != null)
      'japaneseLevelRuleBased1to4': japaneseLevelRuleBased1to4,
    if (recordedAt != null) 'recordedAt': recordedAt!.toIso8601String(),
  };

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    final dateRaw = json['date'] ?? json['timestamp'] ?? json['createdAt'];
    if (dateRaw == null) {
      throw FormatException('missing date');
    }
    final DateTime date = switch (dateRaw) {
      String s => DateTime.parse(s),
      num ms => DateTime.fromMillisecondsSinceEpoch(ms.toInt()),
      _ => throw FormatException('invalid date'),
    };

    final scoreRaw = json['genkiScore'] ?? json['score'] ?? json['genki'];
    final int genkiScore = switch (scoreRaw) {
      int v => v,
      double v => v.round(),
      String s => int.parse(s),
      _ => throw FormatException('invalid genkiScore'),
    };

    final textRaw = json['diaryText'] ?? json['text'] ?? json['diary'];
    if (textRaw == null) {
      throw FormatException('missing diaryText');
    }
    final diaryText = textRaw.toString();

    int? toIntOrNull(dynamic raw) => switch (raw) {
      null => null,
      num v => v.round(),
      String s => int.tryParse(s),
      _ => null,
    };

    return DiaryEntry(
      date: date,
      genkiScore: genkiScore,
      diaryText: diaryText,
      initialMoodScore: toIntOrNull(json['initialMoodScore']),
      positivity: toIntOrNull(json['positivity']),
      stress: toIntOrNull(json['stress']),
      fatigue: toIntOrNull(json['fatigue']),
      motivation: toIntOrNull(json['motivation']),
      japaneseLevel: toIntOrNull(json['japaneseLevel']),
      summary: json['summary'] as String?,
      genkiReason: json['genkiReason'] as String?,
      japaneseReason: json['japaneseReason'] as String?,
      fluencySnapshot: json['fluencySnapshot'] is Map<String, dynamic>
          ? FluencySnapshot.fromJson(
              json['fluencySnapshot'] as Map<String, dynamic>,
            )
          : null,
      japaneseLevelRuleBasedBand: json['japaneseLevelRuleBasedBand'] as String?,
      japaneseLevelRuleBased1to4: toIntOrNull(
        json['japaneseLevelRuleBased1to4'],
      ),
      recordedAt: json['recordedAt'] is String
          ? DateTime.tryParse(json['recordedAt'] as String)
          : null,
    );
  }
}

/// ボイス日記を端末内のJSONファイルに保存する、シンプルなローカルストレージ。
class DiaryStorage {
  static const _fileName = 'osmgenki_diary.json';

  /// 日付を年月日単位でグルーピングするためのキー（例: "2026-07-04"）。
  static String dateKeyFor(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  /// 日本語評点を1〜5からJSSTと同じ1〜10スケールへ変更した際の移行済みフラグ。
  static const _japaneseLevelMigratedToTenScaleKey =
      'osmGenki.japaneseLevelMigratedToTenScale';
  static const _genkiScoreMigratedToTenScaleKey =
      'osmGenki.genkiScoreMigratedToTenScale';

  /// 保存が起きるたびに値をインクリメントする。ダッシュボード/日記一覧は
  /// IndexedStackで常時マウントされたままなので、これを監視して再読込する。
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  /// 読み込み→書き込みを行う全操作を直列化するロック。これが無いと、
  /// 「診断」の送信を連打した場合などに複数の書き込みが同時に走り、
  /// ファイルの途中で上書きが切り替わって内容が壊れることがあった
  /// （実際にSimulatorで、正常なJSON配列の後ろに別の書き込みの断片が
  /// 残る形の破損を確認した）。
  static Future<void> _lock = Future.value();

  /// [action]を、直前にキューされた操作が終わるまで待ってから実行する。
  /// action が例外を投げても[_lock]自体はエラーを握りつぶし、後続の
  /// 操作がブロックされたままにならないようにする。
  static Future<T> _synchronized<T>(Future<T> Function() action) {
    final result = _lock.then((_) => action());
    _lock = result.then((_) {}, onError: (_) {});
    return result;
  }

  static Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _fileName));
  }

  /// ロックを取らない内部専用の読み込み。[_synchronized]でくるんだ
  /// 操作の中からのみ呼ぶこと（二重にロックを取ってデッドロックしないため）。
  static Future<List<DiaryEntry>> _loadAllUnlocked() async {
    final file = await _file();
    if (!await file.exists()) return [];

    String content;
    try {
      content = await file.readAsString();
    } on FileSystemException catch (e) {
      await _quarantineCorruptedFile(file, reason: e.toString());
      return [];
    }
    if (content.trim().isEmpty) return [];

    try {
      final list = jsonDecode(content) as List<dynamic>;
      final entries = list
          .map((e) => DiaryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      entries.sort((a, b) => b.date.compareTo(a.date));
      return entries;
    } on FormatException catch (e) {
      await _quarantineCorruptedFile(file, reason: e.toString());
      return [];
    }
  }

  /// 壊れたファイルをその場で上書きせず、タイムスタンプ付きの別名に退避する。
  /// 一度壊れると読み込みが永久に失敗して以降の保存もできなくなる、という
  /// 詰み状態を避けるため、空リストとして進めるが元データも調査用に残す。
  static Future<void> _quarantineCorruptedFile(
    File file, {
    required String reason,
  }) async {
    try {
      final quarantinePath =
          '${file.path}.corrupted-${DateTime.now().millisecondsSinceEpoch}';
      await file.rename(quarantinePath);
      debugPrint(
        'DiaryStorage: corrupted file quarantined ($reason) -> $quarantinePath',
      );
    } catch (_) {
      // 退避にも失敗した場合はそのまま空リストで進める。
    }
  }

  static Future<List<DiaryEntry>> loadAll() => _synchronized(_loadAllUnlocked);

  /// 直近 [limit] 件の日記を新しい順に取得する。
  static Future<List<DiaryEntry>> loadLatest({int limit = 5}) async {
    final all = await loadAll();
    if (all.length <= limit) return all;
    return all.sublist(0, limit);
  }

  static Future<void> add(DiaryEntry entry) => _synchronized(() async {
    final entries = await _loadAllUnlocked();
    entries.insert(0, entry);
    await _writeAllUnlocked(entries);
  });

  /// インポートなど、複数件をまとめて追加するとき用（書き込み・通知は1回だけ）。
  static Future<void> addAll(List<DiaryEntry> newEntries) =>
      _synchronized(() async {
        if (newEntries.isEmpty) return;
        final entries = await _loadAllUnlocked();
        entries.insertAll(0, newEntries);
        await _writeAllUnlocked(entries);
      });

  /// 1件だけ削除する。エントリーには一意なIDが無いため、作成時刻（[DiaryEntry.date]、
  /// マイクロ秒精度）が一致するものを削除対象とみなす。
  static Future<void> remove(DiaryEntry entry) => _synchronized(() async {
    final entries = await _loadAllUnlocked();
    entries.removeWhere((e) => e.date.isAtSameMomentAs(entry.date));
    await _writeAllUnlocked(entries);
  });

  /// 日本語評点のスケールを1〜5からJSSTと同じ1〜10へ変更した際の、既存データの
  /// 一度きりの移行。旧スケールの値を2倍して10段階に揃える（例: 旧「4」→新「8」）。
  static Future<void> migrateJapaneseLevelToTenScaleIfNeeded(
    SharedPreferences prefs,
  ) => _synchronized(() async {
    if (prefs.getBool(_japaneseLevelMigratedToTenScaleKey) ?? false) return;

    final entries = await _loadAllUnlocked();
    if (entries.any((e) => e.japaneseLevel != null)) {
      final migrated = entries
          .map(
            (e) => e.japaneseLevel == null
                ? e
                : DiaryEntry(
                    date: e.date,
                    genkiScore: e.genkiScore,
                    diaryText: e.diaryText,
                    initialMoodScore: e.initialMoodScore,
                    positivity: e.positivity,
                    stress: e.stress,
                    fatigue: e.fatigue,
                    motivation: e.motivation,
                    japaneseLevel: (e.japaneseLevel! * 2).clamp(1, 10),
                    summary: e.summary,
                    genkiReason: e.genkiReason,
                    japaneseReason: e.japaneseReason,
                    fluencySnapshot: e.fluencySnapshot,
                  ),
          )
          .toList();
      await _writeAllUnlocked(migrated);
    }
    await prefs.setBool(_japaneseLevelMigratedToTenScaleKey, true);
  });

  /// 元気度のスケールを0〜100から0〜10へ変更した際の、一度きりの移行。
  /// 旧スケール値だけを10で割って四捨五入し、0〜10に収める。
  static Future<void> migrateGenkiScoreToTenScaleIfNeeded(
    SharedPreferences prefs,
  ) => _synchronized(() async {
    if (prefs.getBool(_genkiScoreMigratedToTenScaleKey) ?? false) return;

    final entries = await _loadAllUnlocked();
    if (entries.any(
      (e) => e.genkiScore > 10 || (e.initialMoodScore ?? 0) > 10,
    )) {
      int toTenScale(int score) => (score / 10).round().clamp(0, 10);
      final migrated = entries
          .map(
            (e) => DiaryEntry(
              date: e.date,
              genkiScore: toTenScale(e.genkiScore),
              diaryText: e.diaryText,
              initialMoodScore: e.initialMoodScore == null
                  ? null
                  : toTenScale(e.initialMoodScore!),
              positivity: e.positivity,
              stress: e.stress,
              fatigue: e.fatigue,
              motivation: e.motivation,
              japaneseLevel: e.japaneseLevel,
              summary: e.summary,
              genkiReason: e.genkiReason,
              japaneseReason: e.japaneseReason,
              fluencySnapshot: e.fluencySnapshot,
              japaneseLevelRuleBasedBand: e.japaneseLevelRuleBasedBand,
              japaneseLevelRuleBased1to4: e.japaneseLevelRuleBased1to4,
              recordedAt: e.recordedAt,
            ),
          )
          .toList();
      await _writeAllUnlocked(migrated);
    }
    await prefs.setBool(_genkiScoreMigratedToTenScaleKey, true);
  });

  /// 一時ファイルに書いてから本体ファイルへrenameする（アトミック書き込み）。
  /// 書き込みの途中でアプリが強制終了しても、本体ファイルは直前の正常な
  /// 内容のまま残り、中途半端なバイト列で上書きされることがない。
  static Future<void> _writeAllUnlocked(List<DiaryEntry> entries) async {
    final file = await _file();
    final tmpFile = File('${file.path}.tmp');
    await tmpFile.writeAsString(
      jsonEncode(entries.map((e) => e.toJson()).toList()),
      flush: true,
    );
    await tmpFile.rename(file.path);
    changes.value++;
  }

  /// iCloud同期用: ファイルの中身（JSON配列の文字列）をそのまま返す。無ければnull。
  static Future<String?> readRawForSync() => _synchronized(() async {
    final file = await _file();
    if (!await file.exists()) return null;
    return file.readAsString();
  });

  /// iCloud同期用: マージ済みの中身（JSON配列の文字列、nullなら空）で置き換える。
  /// 他の保存と同じロック・アトミック書き込みを使い、一覧・グラフに知らせる。
  static Future<void> replaceRawForSync(String? json) =>
      _synchronized(() async {
        final content = json ?? '[]';
        if (jsonDecode(content) is! List) {
          throw const FormatException('diary sync data is not a list');
        }
        final file = await _file();
        final tmpFile = File('${file.path}.tmp');
        await tmpFile.writeAsString(content, flush: true);
        await tmpFile.rename(file.path);
        changes.value++;
      });

  /// ボイス日記・ダッシュボード（元気度グラフ等）のデータをすべて削除する。
  static Future<void> clearAll() =>
      _synchronized(() => _writeAllUnlocked(const []));
}
