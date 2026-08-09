import 'dart:io';

import '../app_globals.dart';
import 'android_ringtone_service.dart';
import 'ios_sound_service.dart';
import 'system_sound_player.dart';
import 'timer_completion_sound_catalog.dart';

/// osmWashabeの`TimerAlert`を移植。カウントダウンタイマー終了時に、設定で選ばれた
/// 音（iOSシステムサウンド／端末の通知音・着信音）を再生する。
abstract final class TimerAlert {
  static Future<void> playCompletion() async {
    final raw = appSettings.completionSound;
    if (Platform.isAndroid) {
      final ringtone = AndroidRingtoneService.fromStoredValue(raw);
      if (ringtone != null) {
        await AndroidRingtoneService.playRingtone(ringtone.uri);
      } else {
        await SystemSoundPlayer.play(0);
      }
    } else if (Platform.isIOS) {
      if (raw.startsWith('ios_sound:')) {
        final item = IosSoundService.fromStoredValue(raw);
        if (item != null) await IosSoundService.play(item.path);
      } else {
        final item = TimerCompletionSoundCatalog.itemFor(raw);
        if (item != null &&
            item.playable &&
            item.soundId != null &&
            item.storedValue != TimerCompletionSoundCatalog.noneStoredValue) {
          await SystemSoundPlayer.play(item.soundId!);
        }
      }
    }
  }

  /// タイマー音設定画面のプレビュー再生（カタログ項目のみ。着信音自体の試聴は
  /// [IosSoundService.play]/[AndroidRingtoneService.playRingtone]を直接使う）。
  static Future<void> previewSound(String storedValue) async {
    final item = TimerCompletionSoundCatalog.itemFor(storedValue);
    if (item == null || !item.playable || item.soundId == null) return;
    await SystemSoundPlayer.play(item.soundId!);
  }
}
