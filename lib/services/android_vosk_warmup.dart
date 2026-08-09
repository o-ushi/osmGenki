import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'vosk_model_manager.dart';

/// Android 初回録音時に Vosk モデルをバックグラウンドで準備する。
/// 起動時ではなく録音開始パスから [schedule] する想定（起動コストを避ける）。
abstract final class AndroidVoskWarmup {
  static void schedule() {
    if (!Platform.isAndroid) return;
    unawaited(_prepare());
  }

  static Future<void> _prepare() async {
    try {
      if (await VoskModelManager.isReady()) return;
      await VoskModelManager.ensureReady();
    } catch (e, st) {
      // 次回の録音時に再試行する。
      debugPrint('osmGenki: vosk warmup failed: $e\n$st');
    }
  }
}
