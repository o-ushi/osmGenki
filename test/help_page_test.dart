import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:osm_genki/app_globals.dart';
import 'package:osm_genki/l10n/app_strings.dart';
import 'package:osm_genki/screens/help_page.dart';
import 'package:osm_genki/screens/privacy_page.dart';
import 'package:osm_genki/screens/settings_page.dart';
import 'package:osm_genki/services/app_preferences.dart';

const _sections = {
  'talk': 3,
  'rally': 2,
  'save': 3,
  'shake': 1,
  'dashboard': 3,
  'read': 3,
  'review': 3,
  'copy': 3,
  'howto': 1,
  'export': 2,
  'import': 3,
  'icloud': 1,
};

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    appSettings = AppSettings(await AppPreferences.load());
    PackageInfo.setMockInitialValues(
      appName: 'osmGenki',
      packageName: 'com.osamushikubo.osm_genki',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  setUp(() {
    appSettings
      ..language = 'ja'
      ..shakeToTalkEnabled = true;
  });

  Future<void> pump(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(1200, 12000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: page));
    await tester.pumpAndSettle();
  }

  for (final lang in ['ja', 'en', 'vi']) {
    test('$lang: 各節の文言があり、手順は 3 つまでで短い', () {
      for (final MapEntry(key: id, value: count) in _sections.entries) {
        expect(count, lessThanOrEqualTo(3));
        for (final key in [
          'help.$id.title',
          for (var i = 1; i <= count; i++) 'help.$id.$i',
        ]) {
          final text = key.tr(lang);
          expect(text, isNot(key), reason: key);
          expect(text.length, lessThanOrEqualTo(80), reason: key);
        }
      }
    });
  }

  for (final lang in ['en', 'vi']) {
    test('$lang: 手順に日本語が混ざらない', () {
      final japanese = RegExp(r'[぀-ヿ一-鿿]');
      for (final MapEntry(key: id, value: count) in _sections.entries) {
        for (final key in [
          'help.$id.title',
          for (var i = 1; i <= count; i++) 'help.$id.$i',
        ]) {
          expect(japanese.hasMatch(key.tr(lang)), isFalse, reason: key);
        }
      }
    });

    testWidgets('$lang: 幅 320 で全グループを開いても、はみ出さない', (tester) async {
      appSettings
        ..language = lang
        ..developerModeEnabled = true;
      addTearDown(() => appSettings.developerModeEnabled = false);
      tester.view.physicalSize = const Size(960, 12000);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: SettingsPage()));
      await tester.pumpAndSettle();
      for (final key in ['ふだんの使い方', 'データ', '開発者向け']) {
        await tester.tap(find.text(key.tr(lang)));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('操作マニュアルは無く、節は閉じて始まり、開くと番号順の手順が出る', (tester) async {
    await pump(tester, const HelpPage());
    expect(find.byIcon(Icons.menu_book_outlined), findsNothing);
    expect(find.text('help.talk.1'.tr('ja')), findsNothing);

    final card = find.byKey(const ValueKey('help-section-talk'));
    await tester.tap(find.text('help.talk.title'.tr('ja')));
    await tester.pumpAndSettle();
    for (var i = 1; i <= 3; i++) {
      expect(
        find.descendant(of: card, matching: find.text('$i')),
        findsOneWidget,
      );
      expect(find.text('help.talk.$i'.tr('ja')), findsOneWidget);
    }

    await tester.tap(find.text('help.talk.title'.tr('ja')));
    await tester.pumpAndSettle();
    expect(find.text('help.talk.1'.tr('ja')), findsNothing);
  });

  testWidgets('紹介文は短く、プライバシーはヘルプから開く', (tester) async {
    await pump(tester, const HelpPage());
    for (final lang in ['ja', 'en', 'vi']) {
      expect('ヘルプ紹介文'.tr(lang).length, lessThanOrEqualTo(100));
    }
    await tester.tap(find.byKey(const ValueKey('help-privacy')));
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyPage), findsOneWidget);
  });

  testWidgets('シェイクは設定がオンのときだけ、iCloud はiPhone以外で出ない', (tester) async {
    await pump(tester, const HelpPage());
    expect(find.text('help.shake.title'.tr('ja')), findsOneWidget);
    // テストではcloudSyncを作らない（Androidと同じ扱い）。
    expect(find.text('help.icloud.title'.tr('ja')), findsNothing);

    appSettings.shakeToTalkEnabled = false;
    await tester.pumpAndSettle();
    expect(find.text('help.shake.title'.tr('ja')), findsNothing);
  });

  testWidgets('設定: 表示言語は開いたまま、グループは閉じて始まりタップで開く', (tester) async {
    await pump(tester, const SettingsPage());
    expect(find.text('言語'.tr('ja')), findsOneWidget);
    expect(find.text('ふだんの使い方'.tr('ja')), findsOneWidget);
    expect(find.text('データ'.tr('ja')), findsOneWidget);
    expect(find.text('タイマー音'.tr('ja')), findsNothing);

    await tester.tap(find.text('ふだんの使い方'.tr('ja')));
    await tester.pumpAndSettle();
    expect(find.text('タイマー音'.tr('ja')), findsOneWidget);
    expect(find.text('シェイクで話す'.tr('ja')), findsOneWidget);

    await tester.tap(find.text('データ'.tr('ja')));
    await tester.pumpAndSettle();
    expect(find.text('日記をエクスポート'.tr('ja')), findsOneWidget);
    // プライバシーはヘルプへ移した。
    expect(find.text('プライバシー'.tr('ja')), findsNothing);
  });
}
