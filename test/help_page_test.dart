import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:osm_genki/app_globals.dart';
import 'package:osm_genki/l10n/app_strings.dart';
import 'package:osm_genki/screens/help_page.dart';
import 'package:osm_genki/services/app_preferences.dart';

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
    appSettings.language = 'ja';
  });

  test('操作マニュアルURLは言語ごとに固定のpreview先を返す', () {
    expect(
      HelpPage.userManualUrlFor('ja'),
      'https://docs.google.com/presentation/d/'
      '${HelpPage.userManualPresentationIdJa}/preview',
    );
    expect(
      HelpPage.userManualUrlFor('en'),
      'https://docs.google.com/presentation/d/'
      '${HelpPage.userManualPresentationIdEn}/preview',
    );
    expect(
      HelpPage.userManualUrlFor('vi'),
      'https://docs.google.com/presentation/d/'
      '${HelpPage.userManualPresentationIdVi}/preview',
    );
    expect(HelpPage.userManualUrlFor('fr'), HelpPage.userManualUrlFor('vi'));
  });

  testWidgets('操作マニュアルをタップすると表示言語のGoogleスライドが開く', (tester) async {
    final originalUrlLauncher = UrlLauncherPlatform.instance;
    final fakeUrlLauncher = _FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = fakeUrlLauncher;
    addTearDown(() => UrlLauncherPlatform.instance = originalUrlLauncher);

    appSettings.language = 'en';
    addTearDown(() => appSettings.language = AppPreferences.defaultLanguage);

    await tester.pumpWidget(const MaterialApp(home: HelpPage()));
    await tester.pumpAndSettle();

    expect(find.text('操作マニュアル'.tr(appSettings.language)), findsOneWidget);

    await tester.tap(find.byKey(const Key('help_user_manual')));
    await tester.pumpAndSettle();

    expect(fakeUrlLauncher.launchedUrls, [HelpPage.userManualUrlFor('en')]);
    expect(HelpPage.userManualUrlFor('en'), endsWith('/preview'));
  });

  testWidgets('データの説明にバックアップが出て、iCloud同期はiPhone以外では出ない', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HelpPage()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('help.backup.title'.tr('ja')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('help.backup.title'.tr('ja')), findsOneWidget);
    // テストではcloudSyncを作らない（Androidと同じ扱い）。
    expect(find.text('help.icloud.title'.tr('ja')), findsNothing);
  });
}

class _FakeUrlLauncherPlatform extends UrlLauncherPlatform {
  final List<String> launchedUrls = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrls.add(url);
    return true;
  }
}
