import 'package:flutter/material.dart';

import '../app_globals.dart';
import 'mood_selection_page.dart';
import 'startup_screen.dart';
import 'usage_screen.dart';

/// アプリのルート。[StartupScreen]・[UsageScreen]・[MoodSelectionPage]を
/// 切り替えで行き来する（osm日日是好日の AppRootShell と同じ流れ）。
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

  /// 使い方画面の表示状態。起動直後は常に false（スタートアップの「はじめる」を
  /// 経由したときだけ true になる）。
  bool _showingUsage = false;

  void _finishStartup(bool dontShowAgain) {
    // 「はじめる」の着地は使い方フラグだけで決める。チェック ON だと setter の不変条件で
    // 使い方が false になるため、その前の値を見ておく（今回の着地を消さないため）。
    final showUsageNow = appSettings.showUsageScreen;
    if (dontShowAgain) {
      appSettings.showStartupScreen = false;
    }
    setState(() {
      _showingStartup = false;
      _showingUsage = showUsageNow;
    });
  }

  void _finishUsage(bool dontShowAgain) {
    if (dontShowAgain) appSettings.showUsageScreen = false;
    setState(() => _showingUsage = false);
  }

  /// 使い方画面を左端からの右スワイプで閉じたとき。「ホーム画面へ」を押していないので
  /// フラグは保存せずスタートアップへ戻るだけ。
  void _swipeUsageToStartup() {
    setState(() {
      _showingUsage = false;
      _showingStartup = true;
    });
  }

  /// 気分選択画面を左端からの右スワイプで閉じたときに呼ぶ。
  /// 設定の「スタートアップ画面」がONのときだけ[MoodSelectionPage]側から
  /// 渡される。使い方がONなら使い方、OFFならスタートアップへ戻る。
  void _onSwipeFromMood() {
    setState(() {
      if (appSettings.showUsageScreen) {
        _showingUsage = true;
      } else {
        _showingStartup = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showingStartup) {
      return StartupScreen(onContinue: _finishStartup);
    }
    if (_showingUsage) {
      return UsageScreen(
        onContinue: _finishUsage,
        onSwipeToStartup: _swipeUsageToStartup,
      );
    }
    return MoodSelectionPage(onShowStartup: _onSwipeFromMood);
  }
}
