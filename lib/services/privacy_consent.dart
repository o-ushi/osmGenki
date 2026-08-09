import 'package:shared_preferences/shared_preferences.dart';

/// OS音声認識への録音音声提供について、説明文の版と同意状態を管理する。
abstract final class PrivacyConsent {
  static const speechDisclosureVersion = 1;
  static const speechConsentVersionKey =
      'osmGenki.privacy.speechConsentVersion';

  static bool hasCurrentSpeechConsent(SharedPreferences prefs) =>
      prefs.getInt(speechConsentVersionKey) == speechDisclosureVersion;

  static Future<void> grantSpeechConsent(SharedPreferences prefs) =>
      prefs.setInt(speechConsentVersionKey, speechDisclosureVersion);

  static Future<void> revokeSpeechConsent(SharedPreferences prefs) =>
      prefs.remove(speechConsentVersionKey);

  /// 同意されていない場合、外部処理（clipboard/URL起動等）を一切実行しないための共通ガード。
  static Future<bool> runIfAccepted(
    bool accepted,
    Future<void> Function() action,
  ) async {
    if (!accepted) return false;
    await action();
    return true;
  }
}
