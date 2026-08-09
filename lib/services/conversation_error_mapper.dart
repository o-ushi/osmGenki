import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';

/// 会話失敗時にユーザーへ見せるメッセージを、原因別に返す。
String conversationErrorMessage(Object error, String languageCode) {
  if (error is PlatformException) {
    return switch (error.code) {
      'MIC_DENIED' ||
      'SPEECH_DENIED' => 'マイクと音声認識の許可が必要みたい。設定アプリからオンにしてね'.tr(languageCode),
      'SPEECH_UNAVAILABLE' => '音声認識が使えないみたい。ネットワークを確認してね'.tr(languageCode),
      'NO_FILE' ||
      'START_FAILED' => '録音がうまくいかなかったみたい…もう一度試してね'.tr(languageCode),
      _ => '声が届かなかったみたい…もう一度試してね'.tr(languageCode),
    };
  }

  if (error is SttFailure) {
    return switch (error.kind) {
      SttFailureKind.tooShort => 'もう少し長く話してから離してね'.tr(languageCode),
      SttFailureKind.emptyTranscript => '声が届かなかったみたい…もう一度試してね'.tr(languageCode),
      SttFailureKind.permission => 'マイクと音声認識の許可が必要みたい。設定アプリからオンにしてね'.tr(
        languageCode,
      ),
    };
  }

  return '声が届かなかったみたい…もう一度試してね'.tr(languageCode);
}

enum SttFailureKind { tooShort, emptyTranscript, permission }

class SttFailure implements Exception {
  SttFailure(this.kind);
  final SttFailureKind kind;

  @override
  String toString() => 'SttFailure($kind)';
}
