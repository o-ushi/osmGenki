import 'package:shared_preferences/shared_preferences.dart';

/// osmWashabeと同じ、SharedPreferencesをラップした設定の永続化。
class AppPreferences {
  AppPreferences(this._prefs);

  final SharedPreferences _prefs;

  SharedPreferences get sharedPreferences => _prefs;

  static const languageKey = 'osmGenki.language';
  static const defaultLanguage = 'vi';
  static const showStartupScreenKey = 'osmGenki.showStartupScreen';
  static const showUsageScreenKey = 'osmGenki.showUsageScreen';

  // osmWashabeと同じ、設定画面下端の7回タップで切り替わる開発者モード。
  static const developerModeEnabledKey = 'osmGenki.developerModeEnabled';

  static const weekStartsMondayKey = 'osmGenki.weekStartsMonday';

  // osmWashabeと同じ、カウントダウンタイマー終了チャイムの選択音
  // （既定値はosmWashabeのdefaultCompletionSoundと同じ「三連音」）。
  static const completionSoundKey = 'osmGenki.completionSound';
  static const defaultCompletionSound = '1307';

  // osmWashabeのJSST採点キャリブレーション（開発者モード専用）と同じキー構成。
  static const calibrationBiasKey = 'osmGenki.calibration.bias';
  static const calibrationSampleCountKey = 'osmGenki.calibration.sampleCount';

  static const shakeToTalkEnabledKey = 'osmGenki.shakeToTalkEnabled';

  static Future<AppPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AppPreferences(prefs);
  }

  String get language => _prefs.getString(languageKey) ?? defaultLanguage;

  set language(String value) => _prefs.setString(languageKey, value);

  /// 起動時にスタートアップ（案内）画面を出すか。未設定＝初回は true。
  bool get showStartupScreen =>
      _prefs.getBool(showStartupScreenKey) ?? true;

  set showStartupScreen(bool value) =>
      _prefs.setBool(showStartupScreenKey, value);

  /// スタートアップの「はじめる」後に使い方画面を出すか。未設定＝初回は true。
  bool get showUsageScreen => _prefs.getBool(showUsageScreenKey) ?? true;

  set showUsageScreen(bool value) => _prefs.setBool(showUsageScreenKey, value);

  bool get developerModeEnabled =>
      _prefs.getBool(developerModeEnabledKey) ?? false;
  set developerModeEnabled(bool value) =>
      _prefs.setBool(developerModeEnabledKey, value);

  bool get weekStartsMonday => _prefs.getBool(weekStartsMondayKey) ?? false;
  set weekStartsMonday(bool value) =>
      _prefs.setBool(weekStartsMondayKey, value);

  String get completionSound =>
      _prefs.getString(completionSoundKey) ?? defaultCompletionSound;
  set completionSound(String value) =>
      _prefs.setString(completionSoundKey, value);

  double get calibrationBias => _prefs.getDouble(calibrationBiasKey) ?? 0.0;
  set calibrationBias(double value) =>
      _prefs.setDouble(calibrationBiasKey, value);

  int get calibrationSampleCount =>
      _prefs.getInt(calibrationSampleCountKey) ?? 0;
  set calibrationSampleCount(int value) =>
      _prefs.setInt(calibrationSampleCountKey, value);

  void clearCalibration() {
    _prefs.remove(calibrationBiasKey);
    _prefs.remove(calibrationSampleCountKey);
  }

  /// 端末を振って「話す」タブへ切り替えるか。未設定＝従来どおり true。
  bool get shakeToTalkEnabled =>
      _prefs.getBool(shakeToTalkEnabledKey) ?? true;

  set shakeToTalkEnabled(bool value) =>
      _prefs.setBool(shakeToTalkEnabledKey, value);
}
