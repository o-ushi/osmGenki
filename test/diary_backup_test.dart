import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:osm_genki/services/diary_backup.dart';
import 'package:osm_genki/services/diary_review_storage.dart';
import 'package:osm_genki/services/diary_storage.dart';

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  final Directory _dir;

  _FakePathProviderPlatform(this._dir);

  @override
  Future<String?> getApplicationDocumentsPath() async => _dir.path;

  @override
  Future<String?> getTemporaryPath() async => _dir.path;
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('osm_genki_backup_test');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('export then import roundtrip restores diary entries', () async {
    final when = DateTime(2026, 7, 4, 12, 30);
    await DiaryStorage.add(
      DiaryEntry(date: when, genkiScore: 7, diaryText: '今日は散歩した'),
    );

    final exportFile = await DiaryBackup.writeExportFile();
    final exported = jsonDecode(await exportFile.readAsString()) as Map;
    expect(exported['entries'], isA<List>());
    expect((exported['entries'] as List), hasLength(1));

    await DiaryStorage.clearAll();
    expect(await DiaryStorage.loadAll(), isEmpty);

    final result = await DiaryBackup.importFromContent(
      await exportFile.readAsString(),
    );
    expect(result.added, 1);
    expect(result.skipped, 0);

    final restored = await DiaryStorage.loadAll();
    expect(restored, hasLength(1));
    expect(restored.first.genkiScore, 7);
    expect(restored.first.diaryText, '今日は散歩した');
    expect(restored.first.date.toIso8601String(), when.toIso8601String());
  });

  test('import accepts raw array JSON', () async {
    final payload = jsonEncode([
      {
        'date': DateTime(2026, 1, 2).toIso8601String(),
        'genkiScore': 5,
        'diaryText': 'array format',
      },
    ]);

    final result = await DiaryBackup.importFromContent(payload);
    expect(result.added, 1);

    final entries = await DiaryStorage.loadAll();
    expect(entries.single.diaryText, 'array format');
  });

  test('import rejects bundle with unparsable entries', () async {
    final payload = jsonEncode({
      'version': 1,
      'entries': [
        {'date': 'not-a-date', 'genkiScore': 1, 'diaryText': 'x'},
      ],
    });

    expect(
      () => DiaryBackup.importFromContent(payload),
      throwsA(isA<FormatException>()),
    );
  });

  test('export then import roundtrip restores diagnosis results', () async {
    final when = DateTime(2026, 7, 7, 17, 50);
    await DiaryReviewStorage.add(
      DiaryReview(date: when, text: '元気度：9\n1️⃣ 前向きな言葉が多い'),
    );

    final exportFile = await DiaryBackup.writeExportFile();
    final exported = jsonDecode(await exportFile.readAsString()) as Map;
    expect(exported['reviews'], isA<List>());
    expect((exported['reviews'] as List), hasLength(1));

    await DiaryReviewStorage.clearAll();
    expect(await DiaryReviewStorage.loadAll(), isEmpty);

    final result = await DiaryBackup.importFromContent(
      await exportFile.readAsString(),
    );
    expect(result.reviewsAdded, 1);
    expect(result.reviewsSkipped, 0);

    final restored = await DiaryReviewStorage.loadAll();
    expect(restored, hasLength(1));
    expect(restored.first.text, '元気度：9\n1️⃣ 前向きな言葉が多い');
    expect(restored.first.date.toIso8601String(), when.toIso8601String());
  });

  test('import skips duplicate diagnosis results', () async {
    final review = DiaryReview(
      date: DateTime(2026, 3, 1, 9, 0),
      text: 'duplicate review',
    );
    await DiaryReviewStorage.add(review);

    final payload = jsonEncode({
      'entries': [],
      'reviews': [review.toJson()],
    });
    final result = await DiaryBackup.importFromContent(payload);
    expect(result.reviewsAdded, 0);
    expect(result.reviewsSkipped, 1);
    expect(await DiaryReviewStorage.loadAll(), hasLength(1));
  });

  test('import skips duplicates', () async {
    final entry = DiaryEntry(
      date: DateTime(2026, 3, 1),
      genkiScore: 8,
      diaryText: 'duplicate me',
    );
    await DiaryStorage.add(entry);

    final payload = jsonEncode({
      'entries': [entry.toJson()],
    });
    final result = await DiaryBackup.importFromContent(payload);
    expect(result.added, 0);
    expect(result.skipped, 1);
    expect(await DiaryStorage.loadAll(), hasLength(1));
  });
}
