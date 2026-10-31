import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:io';

import 'package:osm_genki/app_globals.dart';
import 'package:osm_genki/l10n/app_strings.dart';
import 'package:osm_genki/main.dart';
import 'package:osm_genki/services/app_preferences.dart';

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    final dir = await Directory.systemTemp.createTemp('osm_genki_startup_test');
    return dir.path;
  }
}

void main() {
  const lang = 'vi';
  String t(String key) => key.tr(lang);

  setUp(() async {
    PathProviderPlatform.instance = _FakePathProviderPlatform();
    SharedPreferences.setMockInitialValues({});
    final prefs = await AppPreferences.load();
    appSettings = AppSettings(prefs);
    // 初回インストール相当：案内を表示する。
    appSettings.showStartupScreen = true;
    // 既存のスタートアップ→気分選択の流れを見るテストでは使い方画面を挟まない。
    appSettings.showUsageScreen = false;
  });

  Future<void> swipeFromLeftEdge(WidgetTester tester) async {
    final gesture = await tester.startGesture(const Offset(16, 300));
    await gesture.moveBy(
      const Offset(40, 0),
      timeStamp: const Duration(milliseconds: 10),
    );
    await gesture.moveBy(
      const Offset(80, 0),
      timeStamp: const Duration(milliseconds: 20),
    );
    await gesture.moveBy(
      const Offset(120, 0),
      timeStamp: const Duration(milliseconds: 30),
    );
    await gesture.up(timeStamp: const Duration(milliseconds: 30));
    await tester.pumpAndSettle();
  }

  group('使い方画面', () {
    setUp(() => appSettings.showUsageScreen = true);

    testWidgets('「はじめる」の後に使い方画面が出て、「ホーム画面へ」で気分選択へ進む', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const OsmGenkiApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text(t('はじめる')));
      await tester.pumpAndSettle();

      expect(find.text(t('使い方')), findsOneWidget);
      expect(find.text(t('ホーム画面へ')), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);

      await tester.tap(find.text(t('ホーム画面へ')));
      await tester.pumpAndSettle();

      expect(appSettings.showUsageScreen, isTrue);
      expect(find.text('元気してる？'), findsOneWidget);
    });

    testWidgets('使い方の「次回から表示しない」で使い方フラグだけOFFになる', (WidgetTester tester) async {
      await tester.pumpWidget(const OsmGenkiApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text(t('はじめる')));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.text(t('ホーム画面へ')));
      await tester.pumpAndSettle();

      expect(appSettings.showUsageScreen, isFalse);
      expect(appSettings.showStartupScreen, isTrue);
      expect(find.text('元気してる？'), findsOneWidget);
    });

    testWidgets('スタートアップをOFFにすると使い方もOFFになる', (WidgetTester tester) async {
      appSettings.showStartupScreen = false;
      expect(appSettings.showUsageScreen, isFalse);
    });

    testWidgets('気分選択から左端の右スワイプで使い方へ、さらにスワイプでスタートアップへ戻る', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const OsmGenkiApp());
      await tester.pumpAndSettle();
      await tester.tap(find.text(t('はじめる')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t('ホーム画面へ')));
      await tester.pumpAndSettle();
      expect(find.text('元気してる？'), findsOneWidget);

      await swipeFromLeftEdge(tester);
      expect(find.text(t('使い方')), findsOneWidget);

      await swipeFromLeftEdge(tester);
      expect(find.text(t('はじめる')), findsOneWidget);
    });
  });

  testWidgets('初回起動ではスタートアップ画面が出る', (WidgetTester tester) async {
    expect(appSettings.showStartupScreen, isTrue);

    await tester.pumpWidget(const OsmGenkiApp());
    await tester.pumpAndSettle();

    expect(find.text('osmGenki？'), findsOneWidget);
    expect(find.text(t('スタートアップ_説明')), findsOneWidget);
    expect(find.text(t('次回から表示しない')), findsOneWidget);
    expect(find.text(t('はじめる')), findsOneWidget);
    expect(find.byType(Checkbox), findsOneWidget);
  });

  testWidgets('文字サイズを大きくしてもアプリ名は拡大されず1行に収まる', (WidgetTester tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const OsmGenkiApp());
    await tester.pumpAndSettle();

    final title = tester.widget<Text>(find.text('osmGenki？'));
    expect(title.maxLines, 1);
    expect(title.textScaler, TextScaler.noScaling);
    expect(title.softWrap, isFalse);

    // システム文字サイズ2倍でも、タイトル高さは等倍の1行分に近い
    // （fontSize 36 + 行メトリクスでおおよそ50前後）。
    final height = tester.getSize(find.text('osmGenki？')).height;
    expect(height, lessThan(60));
  });

  testWidgets('「次回から表示しない」にチェックして始めると、次回は気分選択へ直接進む', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OsmGenkiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text(t('はじめる')));
    await tester.pumpAndSettle();

    expect(appSettings.showStartupScreen, isFalse);
    expect(find.text('元気してる？'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const OsmGenkiApp());
    await tester.pumpAndSettle();

    expect(find.text(t('はじめる')), findsNothing);
    expect(find.text('元気してる？'), findsOneWidget);
  });

  testWidgets('チェックなしで始めると、次回起動でもスタートアップが再表示される', (WidgetTester tester) async {
    await tester.pumpWidget(const OsmGenkiApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text(t('はじめる')));
    await tester.pumpAndSettle();

    expect(appSettings.showStartupScreen, isTrue);
    expect(find.text('元気してる？'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const OsmGenkiApp());
    await tester.pumpAndSettle();

    expect(find.text(t('はじめる')), findsOneWidget);
  });

  testWidgets('国旗ボタンをタップすると言語選択シートが開き、選ぶとその場で言語が切り替わる', (
    WidgetTester tester,
  ) async {
    appSettings.language = 'vi';
    await tester.pumpWidget(const OsmGenkiApp());
    await tester.pumpAndSettle();

    expect(find.text('🇻🇳'), findsOneWidget);
    expect(find.text('スタートアップ_説明'.tr('vi')), findsOneWidget);

    await tester.tap(find.text('🇻🇳'));
    await tester.pumpAndSettle();

    expect(find.text('English'), findsOneWidget);
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(appSettings.language, 'en');
    expect(find.text('🇺🇸'), findsOneWidget);
    expect(find.text('スタートアップ_説明'.tr('en')), findsOneWidget);
  });

  testWidgets('スタートアップ画面表示ONのとき、気分選択画面から左端の右スワイプでスタートアップ画面に戻る', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OsmGenkiApp());
    await tester.pumpAndSettle();
    // 「次回から表示しない」を付けずに始める → showStartupScreenはtrueのまま。
    await tester.tap(find.text(t('はじめる')));
    await tester.pumpAndSettle();

    expect(appSettings.showStartupScreen, isTrue);
    expect(find.text('元気してる？'), findsOneWidget);

    final gesture = await tester.startGesture(const Offset(16, 300));
    await gesture.moveBy(
      const Offset(40, 0),
      timeStamp: const Duration(milliseconds: 10),
    );
    await gesture.moveBy(
      const Offset(80, 0),
      timeStamp: const Duration(milliseconds: 20),
    );
    await gesture.moveBy(
      const Offset(120, 0),
      timeStamp: const Duration(milliseconds: 30),
    );
    await gesture.up(timeStamp: const Duration(milliseconds: 30));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(t('はじめる')), findsOneWidget);
    expect(find.text('元気してる？'), findsNothing);
  });

  testWidgets('スタートアップ画面表示OFFのとき、気分選択画面から左端の右スワイプをしても何も起きない', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OsmGenkiApp());
    await tester.pumpAndSettle();
    // 「次回から表示しない」を付けて始める → showStartupScreenはfalseになる。
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text(t('はじめる')));
    await tester.pumpAndSettle();

    expect(appSettings.showStartupScreen, isFalse);
    expect(find.text('元気してる？'), findsOneWidget);

    final gesture = await tester.startGesture(const Offset(16, 300));
    await gesture.moveBy(
      const Offset(40, 0),
      timeStamp: const Duration(milliseconds: 10),
    );
    await gesture.moveBy(
      const Offset(80, 0),
      timeStamp: const Duration(milliseconds: 20),
    );
    await gesture.moveBy(
      const Offset(120, 0),
      timeStamp: const Duration(milliseconds: 30),
    );
    await gesture.up(timeStamp: const Duration(milliseconds: 30));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(t('はじめる')), findsNothing);
    expect(find.text('元気してる？'), findsOneWidget);
  });
}
