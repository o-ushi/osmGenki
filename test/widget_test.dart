import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:osm_genki/app_globals.dart';
import 'package:osm_genki/main.dart';
import 'package:osm_genki/models/mood_level.dart';
import 'package:osm_genki/services/app_preferences.dart';

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    final dir = await Directory.systemTemp.createTemp('osm_genki_test');
    return dir.path;
  }
}

void main() {
  setUp(() async {
    PathProviderPlatform.instance = _FakePathProviderPlatform();
    SharedPreferences.setMockInitialValues({
      AppPreferences.languageKey: 'ja',
      AppPreferences.showStartupScreenKey: false,
    });
    final prefs = await AppPreferences.load();
    appSettings = AppSettings(prefs);
  });

  Future<void> enterConversation(WidgetTester tester) async {
    await tester.tap(find.byIcon(MoodLevel.neutral.icon));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('Shows the initial greeting and mood buttons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OsmGenkiApp());

    expect(find.text('元気してる？'), findsOneWidget);
    for (final mood in MoodLevel.values) {
      expect(find.byIcon(mood.icon), findsOneWidget);
    }
  });

  testWidgets('Conversation toolbar exposes dashboard and diary actions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OsmGenkiApp());
    await enterConversation(tester);

    expect(find.byIcon(Icons.insights_rounded), findsOneWidget);
    expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.insights_rounded));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.menu_book_rounded));
    await tester.pump();
    expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
  });

  testWidgets('Settings screen lists languages in the osmWashabe order '
      'and switches the app language', (WidgetTester tester) async {
    await tester.pumpWidget(const OsmGenkiApp());
    await enterConversation(tester);

    await tester.tap(find.byIcon(Icons.insights_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('設定'), findsOneWidget);
    final englishFinder = find.text('English');
    final japaneseFinder = find.text('日本語');
    final vietnameseFinder = find.text('Tiếng Việt');
    expect(englishFinder, findsOneWidget);
    expect(japaneseFinder, findsOneWidget);
    expect(vietnameseFinder, findsOneWidget);

    // osmWashabeと同じ並び順: English → 日本語 → Tiếng Việt。
    final englishY = tester.getTopLeft(englishFinder).dy;
    final japaneseY = tester.getTopLeft(japaneseFinder).dy;
    final vietnameseY = tester.getTopLeft(vietnameseFinder).dy;
    expect(englishY, lessThan(japaneseY));
    expect(japaneseY, lessThan(vietnameseY));

    await tester.tap(englishFinder);
    await tester.pump();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
  });
}
