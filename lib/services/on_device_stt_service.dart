import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'android_offline_speech_platform.dart';
import 'conversation_error_mapper.dart';
import 'speech_recognition_debug_log_store.dart';
import 'vosk_model_manager.dart';

/// osmWashabe と同じ「録音 → 端末内 STT」方式。
/// iOS: AVAudioRecorder + SFSpeechRecognizer
/// Android: 無音録音 → SpeechRecognizer（ファイル入力）→ 失敗時のみVoskにフォールバック
class OnDeviceSttService {
  static const _captureChannelName =
      'com.osamushikubo.osm_genki/speech_capture';
  final MethodChannel _captureChannel = const MethodChannel(
    _captureChannelName,
  );

  bool _sessionActive = false;
  bool _recording = false;
  DateTime? _recordingStartedAt;
  String? _lastRecordingPath;

  final List<String> _debugLog = [];

  static const _minRecordingDuration = Duration(milliseconds: 450);

  bool get isRecording => _recording;

  List<String> get debugLog => List.unmodifiable(_debugLog);

  /// 直近に録音した音声ファイルのパス。聴き直しボタン用に、文字起こし後も
  /// 削除せず保持しておく（新しい録音や [clearLastRecording] で入れ替わる）。
  String? get lastRecordingPath => _lastRecordingPath;

  /// 保持している直近の録音を破棄する（会話リセット時に呼ぶ）。
  Future<void> clearLastRecording() async {
    final path = _lastRecordingPath;
    _lastRecordingPath = null;
    if (path == null) return;
    try {
      await File(path).delete();
    } catch (_) {}
  }

  Future<void> _rememberLastRecording(String path) async {
    final previous = _lastRecordingPath;
    _lastRecordingPath = path;
    if (previous != null && previous != path) {
      try {
        await File(previous).delete();
      } catch (_) {}
    }
  }

  /// 録音を開始する。成功したら true。
  Future<bool> startRecording() async {
    if (_recording || _sessionActive) return false;
    _sessionActive = true;
    _log('--- 録音セッション開始 (${Platform.operatingSystem}) ---');

    if (Platform.isAndroid) {
      return _startAndroidRecording();
    }
    return _startIosRecording();
  }

  /// 録音を停止し、端末内 STT で文字起こししたテキストを返す。
  /// [onProgress]はosmWashabeと同じ、Androidでの文字起こし進捗通知
  /// （0.0〜1.0、モデル準備中か解析中かを[TranscribePhase]で伝える）。
  /// iOSは即時変換のため呼ばれない。
  Future<String> stopAndTranscribe({
    void Function(double value, TranscribePhase phase)? onProgress,
  }) async {
    if (!_sessionActive && !_recording) {
      throw SttFailure(SttFailureKind.emptyTranscript);
    }

    final startedAt = _recordingStartedAt;
    if (startedAt != null &&
        DateTime.now().difference(startedAt) < _minRecordingDuration) {
      _log('録音が短すぎるためキャンセル');
      await _cancelActiveRecording();
      throw SttFailure(SttFailureKind.tooShort);
    }

    _sessionActive = false;
    _log('文字起こし開始');
    final text = Platform.isAndroid
        ? await _stopAndroidAndTranscribe(onProgress)
        : await _stopIosAndTranscribe();
    _recordingStartedAt = null;

    if (text.trim().isEmpty) {
      _log('文字起こし結果が空');
      throw SttFailure(SttFailureKind.emptyTranscript);
    }
    _log('文字起こし完了: ${text.trim().length}字');
    return text;
  }

  /// 進行中の録音セッションを、文字起こしせずに中断する。呼び出し側（会話リセットなど）が
  /// [_phase]を勝手にidleへ戻しても、ネイティブ側の録音セッションが生きたままだと
  /// 次の[startRecording]が黙って失敗するため、その中断処理を公開する。
  /// 録音中でなければ何もしない。
  Future<void> cancelRecording() async {
    if (!_sessionActive && !_recording) return;
    await _cancelActiveRecording();
  }

  Future<void> _cancelActiveRecording() async {
    _log('録音キャンセル');
    _sessionActive = false;
    _recordingStartedAt = null;
    if (Platform.isAndroid) {
      await AndroidOfflineSpeechPlatform.cancelRecording();
    } else if (Platform.isIOS) {
      try {
        await _captureChannel.invokeMethod<void>('stopCapture');
      } catch (_) {}
    }
    _recording = false;
  }

  void dispose() {
    _sessionActive = false;
    if (Platform.isAndroid) {
      unawaited(AndroidOfflineSpeechPlatform.cancelRecording());
    } else if (Platform.isIOS) {
      unawaited(
        _captureChannel.invokeMethod<void>('stopCapture').catchError((_) {}),
      );
    }
  }

  Future<bool> _startIosRecording() async {
    final String outputPath;
    try {
      final dir = await getApplicationDocumentsDirectory();
      outputPath = '${dir.path}/osmgenki_last_recording.m4a';
    } catch (e) {
      debugPrint('OnDeviceStt: iOS path failed: $e');
      _sessionActive = false;
      return false;
    }

    try {
      final ok = await _captureChannel
          .invokeMethod<bool>('startCapture', {'outputPath': outputPath})
          .timeout(const Duration(seconds: 8));
      if (ok != true) {
        _sessionActive = false;
        _log('startCapture: 開始失敗');
        return false;
      }
      _recording = true;
      _recordingStartedAt = DateTime.now();
      _log('録音開始(iOS)');
      return true;
    } on SttFailure {
      rethrow;
    } catch (e) {
      debugPrint('OnDeviceStt: iOS start failed: $e');
      _sessionActive = false;
      _log('startCapture例外: $e');
      if (e is PlatformException && e.code == 'MIC_DENIED') {
        throw SttFailure(SttFailureKind.permission);
      }
      return false;
    }
  }

  Future<String> _stopIosAndTranscribe() async {
    String? path;
    if (_recording) {
      try {
        path = await _captureChannel
            .invokeMethod<String>('stopCapture')
            .timeout(const Duration(seconds: 5));
      } catch (e) {
        debugPrint('OnDeviceStt: iOS stop failed: $e');
        _log('録音停止失敗: $e');
      }
      _recording = false;
    }

    if (path == null || path.isEmpty) {
      _log('stopAndTranscribe(iOS): 録音ファイルなし');
      return '';
    }
    await _rememberLastRecording(path);

    try {
      final raw = await _captureChannel
          .invokeMethod<List<dynamic>>('transcribeFile', {'path': path})
          .timeout(const Duration(seconds: 45));
      final text = _joinIosSegments(raw ?? const []);
      if (text.isEmpty) {
        _log('文字起こし結果が空(iOS)');
        return '';
      }
      _log('文字起こし完了(iOS): ${raw?.length ?? 0}セグメント ${text.length}字');
      return text;
    } on PlatformException catch (e) {
      debugPrint('OnDeviceStt: iOS transcribe platform error: $e');
      _log('文字起こし失敗(iOS): ${e.code} ${e.message}');
      if (e.code == 'SPEECH_DENIED') {
        throw SttFailure(SttFailureKind.permission);
      }
      return '';
    } catch (e) {
      debugPrint('OnDeviceStt: iOS transcribe failed: $e');
      _log('文字起こし失敗(iOS): $e');
      return '';
    }
  }

  String _joinIosSegments(List<dynamic> segments) {
    if (segments.isEmpty) return '';
    final words = <String>[];
    for (final raw in segments) {
      final seg = Map<String, dynamic>.from(raw as Map);
      final word = (seg['text'] as String? ?? '').trim();
      if (word.isNotEmpty) words.add(word);
    }
    return words.join(' ').trim();
  }

  Future<bool> _startAndroidRecording() async {
    var permitted = await AndroidOfflineSpeechPlatform.hasRecordPermission();
    if (!permitted) {
      permitted = await AndroidOfflineSpeechPlatform.requestRecordPermission();
    }
    if (!permitted) {
      _sessionActive = false;
      _log('録音許可: false');
      throw SttFailure(SttFailureKind.permission);
    }
    _log('録音許可: true');

    try {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final ok = await AndroidOfflineSpeechPlatform.startRecording();
      if (!ok) {
        _sessionActive = false;
        _log('録音開始失敗(Android)');
        return false;
      }
      _recording = true;
      _recordingStartedAt = DateTime.now();
      _log('録音開始(Android)');
      return true;
    } catch (e) {
      debugPrint('OnDeviceStt: Android start failed: $e');
      _log('録音開始例外(Android): $e');
      _recording = false;
      _sessionActive = false;
      await AndroidOfflineSpeechPlatform.cancelRecording();
      return false;
    }
  }

  /// モデル未準備時、進捗のうちモデル準備に割り当てる割合（osmWashabeと同じ0.3）。
  static const _modelPrepProgressShare = 0.3;

  Future<String> _stopAndroidAndTranscribe(
    void Function(double value, TranscribePhase phase)? onProgress,
  ) async {
    String? wavPath;
    if (_recording) {
      try {
        wavPath = await AndroidOfflineSpeechPlatform.stopRecording().timeout(
          const Duration(seconds: 5),
        );
      } catch (e) {
        debugPrint('OnDeviceStt: Android stop failed: $e');
        _log('録音停止失敗(Android): $e');
      }
      _recording = false;
    } else {
      await AndroidOfflineSpeechPlatform.cancelRecording();
    }

    if (wavPath == null || wavPath.isEmpty) {
      _log('stopAndTranscribe(Android): 録音ファイルなし');
      return '';
    }

    StreamSubscription<double>? progressSub;
    try {
      final fileSize = await File(wavPath).length();
      _log('録音ファイル: ${fileSize}bytes');

      onProgress?.call(0, TranscribePhase.analyzing);
      final onlineText = await AndroidOfflineSpeechPlatform.recognizeOnline(
        wavPath,
        onFailureReason: (reason) => _log('オンライン認識失敗理由: $reason'),
      );
      if (onlineText != null) {
        _log('文字起こし完了(Android/オンライン): ${onlineText.length}字');
        await _rememberLastRecording(wavPath);
        return onlineText;
      }
      _log('オンライン認識不可、Voskにフォールバック');

      final modelReady = await VoskModelManager.isReady();
      if (!modelReady) {
        onProgress?.call(0, TranscribePhase.preparingModel);
        await VoskModelManager.ensureReady(
          onProgress: (p) =>
              onProgress?.call(p * _modelPrepProgressShare, TranscribePhase.preparingModel),
        ).timeout(const Duration(minutes: 10));
      }
      final base = modelReady ? 0.0 : _modelPrepProgressShare;
      final span = modelReady ? 1.0 : 1.0 - _modelPrepProgressShare;
      onProgress?.call(base, TranscribePhase.analyzing);

      progressSub = AndroidOfflineSpeechPlatform.transcribeProgressStream()
          .listen((fraction) {
        // 2.0はモデル読み込み中を表す番兵値（system_sound_player等とは無関係）。
        if (fraction > 1.0) {
          onProgress?.call(0, TranscribePhase.analyzing);
        } else {
          onProgress?.call(base + fraction * span, TranscribePhase.analyzing);
        }
      });

      final modelPath = await VoskModelManager.modelPath();
      final segments = await AndroidOfflineSpeechPlatform.transcribe(
        modelPath: modelPath,
        wavPath: wavPath,
      ).timeout(const Duration(seconds: 120));
      await _rememberLastRecording(wavPath);
      final text = segments
          .map((s) => s.text.trim())
          .where((t) => t.isNotEmpty)
          .join(' ');
      _log('文字起こし完了(Android): segments=${segments.length} ${text.length}字');
      return text;
    } catch (e) {
      debugPrint('OnDeviceStt: Android transcribe failed: $e');
      _log('文字起こし失敗(Android): $e');
      await _rememberLastRecording(wavPath);
      return '';
    } finally {
      await progressSub?.cancel();
    }
  }

  void _log(String message) {
    final stamped =
        '${DateTime.now().toIso8601String().substring(11, 19)} $message';
    _debugLog.add(stamped);
    if (_debugLog.length > 30) _debugLog.removeAt(0);
    unawaited(SpeechRecognitionDebugLogStore.append(stamped));
  }
}

/// [OnDeviceSttService.stopAndTranscribe]の進捗が今どの段階かを表す
/// （osmWashabeの採点中フェーズ表示に対応）。
enum TranscribePhase { preparingModel, analyzing }
