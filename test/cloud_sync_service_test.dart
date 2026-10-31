import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:osm_genki/services/cloud_sync/cloud_sync_service.dart';
import 'package:osm_genki/services/cloud_sync/icloud_bridge.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeBridge implements ICloudBridge {
  bool available = true;
  String? data;
  double timestamp = 0;
  int writes = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<({String? data, double timestamp})> read() async =>
      (data: data, timestamp: timestamp);

  @override
  Future<void> write(String data, double timestamp) async {
    this.data = data;
    this.timestamp = timestamp;
    writes++;
  }

  @override
  Future<void> startObserving(void Function() onExternalChange) async {}
}

class _MemoryBaseStore implements CloudSyncBaseStore {
  CloudSnapshot? value;

  @override
  Future<CloudSnapshot?> read() async => value;

  @override
  Future<void> write(CloudSnapshot snapshot) async => value = snapshot;
}

/// 1台分（同じプロセスでは SharedPreferences が1つなので、端末の中身を差し替えて使う）。
class _Device {
  _Device(this.bridge);

  final _FakeBridge bridge;
  final base = _MemoryBaseStore();
  Map<String, Object> values = {};
  int applied = 0;

  Future<CloudSyncService> open() async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    return CloudSyncService(
      prefs: prefs,
      bridge: bridge,
      baseStore: base,
      onApplied: () async => applied++,
    );
  }

  Future<void> close() async {
    final prefs = await SharedPreferences.getInstance();
    values = {for (final k in prefs.getKeys()) k: prefs.get(k)!};
  }
}

/// JSON配列の値をidの集合にする（並びは端末ごとに変わりうるので比べない）。
Set<Object?> _ids(Object? json) => {
  for (final e in jsonDecode(json! as String) as List) (e as Map)['id'],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('mergeSnapshots', () {
    test('片方だけが変えたキーはその値、削除も伝わる', () {
      final merged = CloudSyncService.mergeSnapshots(
        base: {
          'a': ['i', 1],
          'b': ['s', 'x'],
          'c': ['b', true],
        },
        local: {
          'a': ['i', 2],
          'b': ['s', 'x'],
          'c': ['b', true],
        },
        remote: {
          'a': ['i', 1],
          'b': ['s', 'y'],
        },
      );
      expect(merged, {
        'a': ['i', 2],
        'b': ['s', 'y'],
      });
    });

    test('両方が変えたidの配列は項目単位でマージし、消した項目は戻さない', () {
      String list(List<Map<String, Object>> items) =>
          '[${items.map((e) => '{"id":"${e['id']}","v":${e['v']}}').join(',')}]';
      final merged = CloudSyncService.mergeSnapshots(
        base: {
          'k': [
            's',
            list([
              {'id': '1', 'v': 1},
              {'id': '2', 'v': 1},
            ]),
          ],
        },
        // 端末: 2を消し、3を足した
        local: {
          'k': [
            's',
            list([
              {'id': '1', 'v': 1},
              {'id': '3', 'v': 1},
            ]),
          ],
        },
        // iCloud: 1を書き換え、4を足した
        remote: {
          'k': [
            's',
            list([
              {'id': '1', 'v': 2},
              {'id': '2', 'v': 1},
              {'id': '4', 'v': 1},
            ]),
          ],
        },
      );
      expect(merged['k'], [
        's',
        list([
          {'id': '1', 'v': 2},
          {'id': '3', 'v': 1},
          {'id': '4', 'v': 1},
        ]),
      ]);
    });

    test('初回（基準が空）は両方の文字列配列を残す', () {
      final merged = CloudSyncService.mergeSnapshots(
        base: {},
        local: {
          't': [
            'l',
            ['a', 'b'],
          ],
        },
        remote: {
          't': [
            'l',
            ['b', 'c'],
          ],
        },
      );
      expect(merged['t'], [
        'l',
        ['a', 'b', 'c'],
      ]);
    });

    test('両方が変えた値（配列以外）はiCloudを採る', () {
      final merged = CloudSyncService.mergeSnapshots(
        base: {
          'r': ['d', 1.0],
        },
        local: {
          'r': ['d', 1.2],
        },
        remote: {
          'r': ['d', 0.8],
        },
      );
      expect(merged['r'], ['d', 0.8]);
    });
  });

  test('日記は date で見分け、両端末の追加をどちらも残す', () {
    String e(String date, {int score = 5}) =>
        '{"date":"$date","genkiScore":$score,"diaryText":"t"}';
    String list(List<String> items) => '[${items.join(',')}]';
    final merged = CloudSyncService.mergeSnapshots(
      base: {
        'file.diary': [
          's',
          list([e('2026-10-01T10:00:00.000001')]),
        ],
      },
      local: {
        'file.diary': [
          's',
          list([
            e('2026-10-02T09:00:00.000002'),
            e('2026-10-01T10:00:00.000001'),
          ]),
        ],
      },
      remote: {
        'file.diary': [
          's',
          list([
            e('2026-10-03T08:00:00.000003'),
            e('2026-10-01T10:00:00.000001'),
          ]),
        ],
      },
    );
    final items = jsonDecode(merged['file.diary']![1]! as String) as List;
    expect(items.map((e) => (e as Map)['date']), [
      '2026-10-02T09:00:00.000002',
      '2026-10-01T10:00:00.000001',
      '2026-10-03T08:00:00.000003',
    ]);
  });

  test('端末ごとのキーは同期しない', () {
    expect(CloudSyncService.isSyncedKey('osmGenki.language'), isFalse);
    expect(CloudSyncService.isSyncedKey('osmGenki.showStartupScreen'), isFalse);
    expect(CloudSyncService.isSyncedKey('osmGenki.showUsageScreen'), isFalse);
    expect(
      CloudSyncService.isSyncedKey('osmGenki.developerModeEnabled'),
      isFalse,
    );
    expect(
      CloudSyncService.isSyncedKey('osmGenki.genkiScoreMigratedToTenScale'),
      isFalse,
    );
    expect(CloudSyncService.isSyncedKey('cloudSync.enabled'), isFalse);
    expect(
      CloudSyncService.isSyncedKey('osmGenki.privacy.speechConsentVersion'),
      isFalse,
    );
    expect(CloudSyncService.isSyncedKey('osmGenki.calibration.bias'), isFalse);
    expect(CloudSyncService.isSyncedKey('file.diary'), isFalse);
    expect(CloudSyncService.isSyncedKey('osmGenki.weekStartsMonday'), isTrue);
    expect(CloudSyncService.isSyncedKey('osmGenki.completionSound'), isTrue);
    expect(CloudSyncService.isSyncedKey('osmGenki.shakeToTalkEnabled'), isTrue);
  });

  test('空の配列・無いファイルは同じ（null）に揃える', () {
    expect(CloudSyncService.normalizeFileJson(null), isNull);
    expect(CloudSyncService.normalizeFileJson(''), isNull);
    expect(CloudSyncService.normalizeFileJson('[]'), isNull);
    expect(
      CloudSyncService.normalizeFileJson('[ {"date": "d"} ]'),
      '[{"date":"d"}]',
    );
  });

  test('2台: 日記ファイルも取り込み・送り返す', () async {
    final bridge = _FakeBridge();
    String? fileA = '[{"date":"a","genkiScore":5,"diaryText":"A"}]';
    String? fileB = '[{"date":"b","genkiScore":7,"diaryText":"B"}]';
    CloudSyncService open(
      SharedPreferences prefs,
      _MemoryBaseStore base,
      bool isA,
    ) => CloudSyncService(
      prefs: prefs,
      bridge: bridge,
      baseStore: base,
      onApplied: () async {},
      files: [
        CloudSyncFile(
          key: 'file.diary',
          read: () async => isA ? fileA : fileB,
          write: (json) async => isA ? fileA = json : fileB = json,
        ),
      ],
    );
    final baseA = _MemoryBaseStore();
    final baseB = _MemoryBaseStore();

    SharedPreferences.setMockInitialValues({CloudSyncService.enabledKey: true});
    var prefs = await SharedPreferences.getInstance();
    await open(prefs, baseA, true).sync();
    expect(bridge.writes, 1);

    SharedPreferences.setMockInitialValues({CloudSyncService.enabledKey: true});
    prefs = await SharedPreferences.getInstance();
    await open(prefs, baseB, false).sync();
    Set<Object?> dates(String? json) =>
        (jsonDecode(json!) as List).map((e) => (e as Map)['date']).toSet();
    expect(dates(fileB), {'a', 'b'});
    expect(bridge.writes, 2);

    SharedPreferences.setMockInitialValues({
      CloudSyncService.enabledKey: true,
      CloudSyncService.confirmedKey: true,
      CloudSyncService.seenRemoteTimestampKey: 0.0,
    });
    prefs = await SharedPreferences.getInstance();
    await open(prefs, baseA, true).sync();
    expect(dates(fileA), {'a', 'b'});
  });

  test('payloadは往復で型を保つ', () {
    final snapshot = <String, List<Object?>>{
      'b': ['b', true],
      'i': ['i', 3],
      'd': ['d', 1.5],
      's': ['s', 'あ'],
      'l': [
        'l',
        ['x', 'y'],
      ],
    };
    expect(
      CloudSyncService.decodePayload(CloudSyncService.encodePayload(snapshot)),
      snapshot,
    );
  });

  test('同期オフでは送らない・受けない', () async {
    final bridge = _FakeBridge();
    final device = _Device(bridge)..values = {'test.list': '[]'};
    final sync = await device.open();
    await sync.sync();
    expect(bridge.writes, 0);
  });

  test('iCloud未サインインなら送らず、状態をunavailableにする', () async {
    final bridge = _FakeBridge()..available = false;
    final device = _Device(bridge)
      ..values = {CloudSyncService.enabledKey: true};
    final sync = await device.open();
    await sync.sync();
    expect(bridge.writes, 0);
    expect(sync.status, CloudSyncStatus.unavailable);
  });

  test('iCloudが空なら、初回でも端末の中身を送る（どの端末も送らず止まらない）', () async {
    final bridge = _FakeBridge();
    final device = _Device(bridge)
      ..values = {CloudSyncService.enabledKey: true, 'x': 'local'};
    final sync = await device.open();
    await sync.sync();
    expect(bridge.writes, 1);
    expect(CloudSyncService.decodePayload(bridge.data!)['x'], ['s', 'local']);
  });

  test('初回ダウンロード前の書き込みがiOSに捨てられても、届いたiCloudの記録は消さない', () async {
    final bridge = _FakeBridge();
    // B が先に iCloud に記録を置いていた
    final b = _Device(bridge)
      ..values = {CloudSyncService.enabledKey: true, 'onlyB': 'b'};
    var sync = await b.open();
    await sync.sync();
    await b.close();
    final cloudData = bridge.data;
    final cloudTs = bridge.timestamp;

    // A はまだ iCloud が届いておらず空に見える → 自分の中身を送る
    bridge
      ..data = null
      ..timestamp = 0;
    final a = _Device(bridge)
      ..values = {CloudSyncService.enabledKey: true, 'onlyA': 'a'};
    sync = await a.open();
    await sync.sync();
    // iOS がその書き込みを捨て、初回ダウンロードで B の記録が届いた
    bridge
      ..data = cloudData
      ..timestamp = cloudTs;
    await sync.sync();
    await a.close();
    expect(a.values['onlyA'], 'a');
    expect(a.values['onlyB'], 'b');
    expect(
      CloudSyncService.decodePayload(bridge.data!).keys,
      containsAll(['onlyA', 'onlyB']),
    );
  });

  test('「今すぐ同期」は送るものが無くても成功を返し、最終同期を更新する', () async {
    final bridge = _FakeBridge();
    final device = _Device(bridge)
      ..values = {CloudSyncService.enabledKey: true, 'x': 'local'};
    final sync = await device.open();
    expect(await sync.manualSync(), isTrue); // 送る
    expect(await sync.manualSync(), isTrue); // 読み戻して確かめる
    final writes = bridge.writes;
    final before = sync.lastSyncDate;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    expect(await sync.manualSync(), isTrue); // 何も変わっていない
    expect(bridge.writes, writes);
    expect(sync.lastSyncDate!.isAfter(before!), isTrue);
    expect(sync.isWorking, isFalse);
  });

  test('iCloud未サインインなら「今すぐ同期」はfalse', () async {
    final bridge = _FakeBridge()..available = false;
    final device = _Device(bridge)
      ..values = {CloudSyncService.enabledKey: true};
    final sync = await device.open();
    expect(await sync.manualSync(), isFalse);
  });

  test('上限を超えるデータは送らずエラーにする', () async {
    final bridge = _FakeBridge();
    // gzipで縮まないよう、乱数に近い文字列にする。
    final noise = List.generate(
      900000,
      (i) => String.fromCharCode(0x4E00 + (i * 7919) % 20000),
    ).join();
    final device = _Device(bridge)
      ..values = {CloudSyncService.enabledKey: true, 'big': noise};
    final sync = await device.open();
    await sync.sync();
    expect(bridge.writes, 0);
    expect(sync.error, CloudSyncError.tooLarge);
  });

  test('2台: 追加・削除・言語は端末ごと、が相手に伝わる', () async {
    final bridge = _FakeBridge();
    final a = _Device(bridge)
      ..values = {
        CloudSyncService.enabledKey: true,
        'osmGenki.language': 'ja',
        'test.list': '[{"id":"1","w":"猫"}]',
        'test.strings': <String>['お題A'],
      };
    final b = _Device(bridge)
      ..values = {
        CloudSyncService.enabledKey: true,
        'osmGenki.language': 'vi',
        'test.list': '[{"id":"2","w":"犬"}]',
      };

    // A が最初に送る
    var sync = await a.open();
    await sync.sync();
    await a.close();
    expect(bridge.writes, 1);

    // B は初回: 両方の単語を残して送り返す
    sync = await b.open();
    await sync.sync();
    await b.close();
    expect(b.values['osmGenki.language'], 'vi');
    expect(_ids(b.values['test.list']), {'1', '2'});
    expect(b.values['test.strings'], ['お題A']);
    expect(bridge.writes, 2);

    // A が取り込む
    sync = await a.open();
    await sync.sync();
    await a.close();
    expect(a.values['osmGenki.language'], 'ja');
    expect(_ids(a.values['test.list']), {'1', '2'});
    expect(a.applied, 1);

    // A で「猫」を消してお題を消す → B でも消える（古いBから復活しない）
    a.values['test.list'] = '[{"id":"2","w":"犬"}]';
    a.values.remove('test.strings');
    sync = await a.open();
    await sync.sync();
    await a.close();

    sync = await b.open();
    await sync.sync();
    await b.close();
    expect(_ids(b.values['test.list']), {'2'});
    expect(b.values.containsKey('test.strings'), isFalse);

    // 変わっていなければ送らない
    final before = bridge.writes;
    sync = await b.open();
    await sync.sync();
    expect(bridge.writes, before);
  });
}
