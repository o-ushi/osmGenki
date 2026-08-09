import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_globals.dart';
import 'screens/app_root.dart';
import 'services/android_ringtone_service.dart';
import 'services/app_preferences.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // スマホ専用アプリのため、端末サイズによらず縦向きに固定する
  // （iOSはInfo.plist/TARGETED_DEVICE_FAMILY、AndroidはManifestのscreenOrientation/
  // supports-screensでも同様に固定・タブレット除外している。これはその保険）。
  await SystemChrome.setPreferredOrientations(
    Platform.isIOS
        ? [DeviceOrientation.portraitUp]
        : [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
  );
  final prefs = await AppPreferences.load();
  appSettings = AppSettings(prefs);
  unawaited(_migrateAndroidDefaultCompletionSound());
  runApp(const OsmGenkiApp());
}

/// iOSのサウンドID（既定値'1307'＝三連音）がAndroidに残ったままだと、設定画面に
/// 意味のない「三連音」表示が出て、実際の再生も端末の音ではなく汎用ビープ音に
/// なってしまう。まだ何も選んでいない場合に限り、端末の既定の通知音に置き換える。
Future<void> _migrateAndroidDefaultCompletionSound() async {
  if (!Platform.isAndroid) return;
  if (appSettings.completionSound != AppPreferences.defaultCompletionSound) {
    return;
  }
  final defaultRingtone = await AndroidRingtoneService.getDefaultRingtone();
  if (defaultRingtone != null) {
    appSettings.completionSound = defaultRingtone.storedValue;
  }
}

class OsmGenkiApp extends StatefulWidget {
  const OsmGenkiApp({super.key});

  @override
  State<OsmGenkiApp> createState() => _OsmGenkiAppState();
}

class _OsmGenkiAppState extends State<OsmGenkiApp> {
  @override
  void initState() {
    super.initState();
    appSettings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    appSettings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() => setState(() {});

  Locale get _locale => switch (appSettings.language) {
    'en' => const Locale('en'),
    'vi' => const Locale('vi'),
    _ => const Locale('ja'),
  };

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'osmGenki？',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      // 端末のダークモードには追従しない。色は常に固定パレット（AppColors.current）。
      themeMode: ThemeMode.light,
      theme: AppTheme.light(),
      home: const AppRoot(),
    );
  }
}
