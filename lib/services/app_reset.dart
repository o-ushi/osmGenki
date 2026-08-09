import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'diary_review_storage.dart';
import 'diary_storage.dart';

/// プライバシー画面の「初期化」。保存された日記・診断結果と、すべての設定
/// （言語・外観・タイマー音・開発者モードなど）を削除し、初めてインストールした
/// 状態に戻す。
abstract final class AppReset {
  static Future<void> resetToFactoryDefaults() async {
    await DiaryStorage.clearAll();
    await DiaryReviewStorage.clearAll();
    await deletePrivateArtifacts();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// SharedPreferences外に残る録音、破損退避、アトミック書込途中、一時exportを削除する。
  /// 引数はテスト用。通常はpath_providerが返すアプリ専用領域を使用する。
  static Future<void> deletePrivateArtifacts({
    Directory? documentsDirectory,
    Directory? temporaryDirectory,
  }) async {
    final documents =
        documentsDirectory ?? await getApplicationDocumentsDirectory();
    final temporary = temporaryDirectory ?? await getTemporaryDirectory();
    await _deleteMatching(documents, (name) {
      return name == 'osmgenki_last_recording.m4a' ||
          name == 'osmgenki_diary_reviews.json' ||
          name.startsWith('osmgenki_diary.json');
    });
    await _deleteMatching(temporary, (name) {
      return (name.startsWith('osmGenki_diary_') && name.endsWith('.json')) ||
          (name.startsWith('osm_genki_speech_') && name.endsWith('.wav')) ||
          name == 'osm_genki_silence.wav';
    });
  }

  static Future<void> _deleteMatching(
    Directory directory,
    bool Function(String name) matches,
  ) async {
    if (!await directory.exists()) return;
    await for (final entity in directory.list(followLinks: false)) {
      if (!matches(p.basename(entity.path))) continue;
      try {
        await entity.delete(recursive: true);
      } catch (e, st) {
        // 初期化は、既に消えたファイルやOS側の一時ロックがあっても継続する。
        debugPrint('osmGenki: reset delete skipped ${entity.path}: $e\n$st');
      }
    }
  }
}
