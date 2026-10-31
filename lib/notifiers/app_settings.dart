import 'package:flutter/foundation.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../services/app_preferences.dart';

/// osmWashabeと同じ、ChangeNotifierベースの設定管理（Provider等は使わない）。
class AppSettings extends ChangeNotifier {
  AppSettings(this._prefs);

  final AppPreferences _prefs;

  String get language => _prefs.language;

  set language(String value) {
    _prefs.language = value;
    notifyListeners();
  }

  /// 起動時のスタートアップ（案内）画面を出すか。
  bool get showStartupScreen => _prefs.showStartupScreen;

  /// OFF にするときは使い方画面も一緒に OFF にする（osm日日是好日と同じ不変条件:
  /// 使い方はスタートアップが ON のときだけ ON。スタートアップだけ再度 ON にしても
  /// 使い方は自動では戻さない）。
  set showStartupScreen(bool value) {
    final usageShouldTurnOff = !value && _prefs.showUsageScreen;
    if (_prefs.showStartupScreen == value && !usageShouldTurnOff) return;
    _prefs.showStartupScreen = value;
    if (usageShouldTurnOff) _prefs.showUsageScreen = false;
    notifyListeners();
  }

  /// スタートアップの「はじめる」後に使い方画面を出すか。
  bool get showUsageScreen => _prefs.showUsageScreen;

  set showUsageScreen(bool value) {
    if (_prefs.showUsageScreen == value) return;
    _prefs.showUsageScreen = value;
    notifyListeners();
  }

  SharedPreferences get prefs => _prefs.sharedPreferences;

  /// osmWashabeと同じ、設定画面下端の7回タップで切り替わる開発者モード。
  /// 有効な間は設定画面に「音声認識ログ」など開発者向け項目を表示する。
  bool get developerModeEnabled => _prefs.developerModeEnabled;

  set developerModeEnabled(bool value) {
    _prefs.developerModeEnabled = value;
    notifyListeners();
  }

  /// ダッシュボードのカレンダーを月曜始まりで表示するか（既定は日曜始まり）。
  bool get weekStartsMonday => _prefs.weekStartsMonday;

  set weekStartsMonday(bool value) {
    _prefs.weekStartsMonday = value;
    notifyListeners();
  }

  /// osmWashabeと同じ、カウントダウンタイマー終了チャイムの選択音（保存値の形式は
  /// TimerCompletionSoundCatalog/IosSoundService/AndroidRingtoneService参照）。
  String get completionSound => _prefs.completionSound;

  set completionSound(String value) {
    _prefs.completionSound = value;
    notifyListeners();
  }

  /// osmWashabeと同じ、JSST採点キャリブレーション（開発者モード専用）の補正係数。
  double get calibrationBias => _prefs.calibrationBias;

  set calibrationBias(double value) {
    _prefs.calibrationBias = value;
    notifyListeners();
  }

  int get calibrationSampleCount => _prefs.calibrationSampleCount;

  set calibrationSampleCount(int value) {
    _prefs.calibrationSampleCount = value;
    notifyListeners();
  }

  void clearCalibration() {
    _prefs.clearCalibration();
    notifyListeners();
  }

  /// 端末を振って「話す」タブへ切り替えるか。
  bool get shakeToTalkEnabled => _prefs.shakeToTalkEnabled;

  set shakeToTalkEnabled(bool value) {
    if (_prefs.shakeToTalkEnabled == value) return;
    _prefs.shakeToTalkEnabled = value;
    notifyListeners();
  }

  /// [AppReset]など、プリファレンスを直接クリアした後にリスナーへ再読み込みを
  /// 促す。プロパティは常に[_prefs]から読み直すため、ここでは通知するだけでよい。
  void refresh() => notifyListeners();
}
