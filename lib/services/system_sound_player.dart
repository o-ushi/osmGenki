import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';

import 'background_audio_keeper.dart';

/// osmWashabeの`SystemSoundPlayer`を移植。iOS / Android のシステム効果音を
/// MethodChannel経由で再生する（カウントダウン終了のチャイム用）。
abstract final class SystemSoundPlayer {
  static const _channel = MethodChannel(
    'com.osamushikubo.osm_genki/system_sound',
  );

  /// [soundId]はiOSのシステムサウンドID（例: 1307 = 三連音）。Android側は
  /// ネイティブ実装で固定のビープ音を鳴らすため、この値は使われない。
  static Future<void> play(int soundId, {bool prepareSession = true}) async {
    if (prepareSession) {
      await _prepareAudioSession();
    }
    if (Platform.isIOS || Platform.isAndroid) {
      try {
        await _channel.invokeMethod<void>('play', soundId);
        return;
      } catch (_) {}
    }
    await SystemSound.play(SystemSoundType.alert);
  }

  static Future<void> _prepareAudioSession() async {
    if (BackgroundAudioKeeper.instance.isRunning) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          avAudioSessionCategoryOptions:
              AVAudioSessionCategoryOptions.mixWithOthers,
        ),
      );
      await session.setActive(true);
    } catch (_) {}
  }
}
