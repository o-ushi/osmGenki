import 'package:flutter/material.dart';

import '../app_globals.dart';
import 'mood_selection_page.dart';
import 'startup_screen.dart';

/// アプリのルート。[StartupScreen]と[MoodSelectionPage]を切り替えで行き来する。
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  /// このプロセス起動中にスタートアップを出した／閉じた状態。
  /// 設定で再有効にしても、同じ起動セッションでは出し直さない
  /// （次回コールドスタートで表示する）。
  late bool _showingStartup = appSettings.showStartupScreen;

  void _finishStartup(bool dontShowAgain) {
    if (dontShowAgain) {
      appSettings.showStartupScreen = false;
    }
    setState(() => _showingStartup = false);
  }

  /// 気分選択画面を左端からの右スワイプで閉じたときに呼ぶ。
  /// 設定の「スタートアップ画面」がONのときだけ[MoodSelectionPage]側から
  /// 渡されるため、ここでは条件を見ずにそのまま表示し直せばよい。
  void _showStartup() {
    setState(() => _showingStartup = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_showingStartup) {
      return StartupScreen(onContinue: _finishStartup);
    }
    return MoodSelectionPage(onShowStartup: _showStartup);
  }
}
