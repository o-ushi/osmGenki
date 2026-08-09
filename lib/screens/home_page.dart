import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../app_constants.dart';
import '../app_globals.dart';
import '../l10n/app_strings.dart';
import '../models/jsst_scoring_models.dart';
import '../models/mood_level.dart';
import '../services/android_vosk_warmup.dart';
import '../services/background_audio_keeper.dart';
import '../services/chrome_ai_prompts.dart';
import '../services/chrome_ai_result_parser.dart';
import '../services/chrome_ai_round_trip.dart';
import '../services/conversation_error_mapper.dart';
import '../services/diary_backup_actions.dart';
import '../services/diary_storage.dart';
import '../services/genki_score_calculator.dart';
import '../services/jsst_score_combiner.dart';
import '../services/jsst_scoring_service.dart';
import '../services/on_device_stt_service.dart';
import '../services/privacy_consent.dart';
import '../services/shake_detector_service.dart';
import '../services/timer_alert.dart';
import '../theme/app_colors.dart';
import '../widgets/appearance_background_layer.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/genki_help_sheet.dart';
import '../widgets/genki_more_actions_menu.dart';
import '../widgets/genki_toolbar.dart';
import '../widgets/swipe_down_to_dismiss.dart';
import 'dashboard_page.dart';
import 'diary_list_page.dart';
import 'help_page.dart';
import 'settings_page.dart';

enum _Phase { idle, recording, processing }

enum _MainTab { talk, dashboard, diary }

/// マイク画面の録音モード。フリーはタップで録音開始／終了をトグル、それ以外は
/// タップ1回で固定秒数のカウントダウン録音を行う。
enum _RecordingDurationMode { free, seconds30, seconds45, seconds60 }

extension on _RecordingDurationMode {
  /// フリー以外のモードでのカウントダウン秒数。フリーはnull。
  int? get fixedSeconds => switch (this) {
    _RecordingDurationMode.free => null,
    _RecordingDurationMode.seconds30 => 30,
    _RecordingDurationMode.seconds45 => 45,
    _RecordingDurationMode.seconds60 => 60,
  };

  /// 選択ボタンに表示するラベルの翻訳キー（アクセシビリティ・Tooltip用）。
  String get labelKey => switch (this) {
    _RecordingDurationMode.free => 'フリー',
    _RecordingDurationMode.seconds30 => '30秒',
    _RecordingDurationMode.seconds45 => '45秒',
    _RecordingDurationMode.seconds60 => '60秒',
  };

  /// 選択ボタンの表示用。フリーはアイコンのみ、秒数モードは数字のみ（「秒」を省く）。
  String? get displaySeconds => switch (this) {
    _RecordingDurationMode.free => null,
    _RecordingDurationMode.seconds30 => '30',
    _RecordingDurationMode.seconds45 => '45',
    _RecordingDurationMode.seconds60 => '60',
  };
}

/// 直近に選ばれた録音モード。リセットで気分選択画面へ戻って[HomePage]が
/// 作り直されても、次のセッションで選択し直さずに済むようアプリ内で覚えておく。
_RecordingDurationMode _lastDurationMode = _RecordingDurationMode.free;

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.moodLevel});

  /// 気分選択画面から渡された、選択済みの元気度区分。
  final MoodLevel? moodLevel;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final OnDeviceSttService _stt = OnDeviceSttService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _moreButtonKey = GlobalKey();
  final _shakeDetector = ShakeDetectorService();

  _Phase _phase = _Phase.idle;
  _MainTab _tab = _MainTab.talk;
  late String _displayPromptKey;
  String? _errorMessage;

  /// osmWashabeと同じ、Android文字起こし中の進捗（0.0〜1.0）。iOSや進捗不明時はnull。
  double? _transcribeProgress;
  TranscribePhase _transcribePhase = TranscribePhase.analyzing;

  /// 1回分の録音区間で認識したテキストを、録音を終えるたびに追記していくバッファ
  /// （osmWashabe方式：録音停止後にまとめて端末内STTで文字起こしする）。
  String _voiceInputText = '';

  /// [_voiceInputText]と並行して溜める、区切り（録音区間1回）ごとの認識結果と時刻。
  /// JSST採点（[JsstScoringService]）の流暢さ軸で、間の沈黙・発話速度を見るのに使う。
  final List<TranscriptChunk> _voiceChunks = [];

  /// 今回の発話ターンで最初に録音を始めた時刻。JSST採点の「持ち時間」の起点。
  DateTime? _sessionStartedAt;

  /// 直近の録音区間（1回分）を開始した時刻。[TranscriptChunk.recognizedAt]には
  /// 文字起こし完了時刻ではなくこの録音開始時刻を使う（osmWashabeの連続録音セグメントの
  /// 開始時刻と同じ意味）。端末内STTの処理待ち時間（数秒かかることがある）が沈黙として
  /// 誤ってカウントされ、流暢さの評価が実際より低くなるのを防ぐため。
  DateTime? _currentPressStartedAt;

  /// 直近に録音を止めた（録音区間を終えた）実時刻。発話枠の終点として使う
  /// （[_voiceChunks]の最終チャンクの[TranscriptChunk.recognizedAt]は録音"開始"時刻のため、
  /// セッション終了時刻には使えない）。
  DateTime? _lastReleasedAt;

  /// クリップボードへコピー済みで、Chrome AIモードの解析結果の貼り付け待ち。
  bool _awaitingPasteResult = false;

  /// 直近の録音を再生中かどうか（聴き直しボタンの状態表示用）。
  bool _isPlayingRecording = false;

  /// 今の発話内容を日記へ登録済みかどうか。登録後も録音データはリセットまで
  /// 残すが、二重登録を防ぐため送信ボタンはこれがtrueの間押せなくする。
  bool _isSessionSaved = false;

  /// マイク画面上部で選ぶ録音モード（フリー＝タップで開始／終了／固定秒数＝タップしてカウントダウン）。
  /// リセット後も前回の選択を維持したいので、[_lastDurationMode]から引き継ぐ。
  _RecordingDurationMode _durationMode = _lastDurationMode;

  /// 固定秒数モードでのカウントダウン残り秒数。フリーモード・非録音中はnull。
  int? _countdownSecondsLeft;
  Timer? _countdownTimer;

  /// カウントダウン中にマイクボタンをタップして一時停止しているかどうか。
  /// 一時停止中は[_countdownSecondsLeft]を変えず、ボタンの色だけ元に戻す。
  bool _isCountdownPaused = false;

  /// Chrome 往復用に開始した無音キープアライブ（Android）。
  bool _startedKeeperForChromeSession = false;

  /// Android Vosk モデルのウォームアップを、初回録音開始時に一度だけ走らせる。
  static bool _voskWarmupStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _displayPromptKey = AppStrings.randomTalkPromptKey();
    unawaited(
      DiaryStorage.migrateJapaneseLevelToTenScaleIfNeeded(appSettings.prefs),
    );
    unawaited(
      DiaryStorage.migrateGenkiScoreToTenScaleIfNeeded(appSettings.prefs),
    );
    appSettings.addListener(_onSettingsChanged);
    _syncShakeDetector();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlayingRecording = false);
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    if (_phase == _Phase.recording) unawaited(WakelockPlus.disable());
    WidgetsBinding.instance.removeObserver(this);
    _stopChromeKeepAliveIfOwned();
    appSettings.removeListener(_onSettingsChanged);
    _stt.dispose();
    _audioPlayer.dispose();
    _shakeDetector.dispose();
    super.dispose();
  }

  void _onSettingsChanged() {
    _syncShakeDetector();
    setState(() {});
  }

  void _syncShakeDetector() {
    if (appSettings.shakeToTalkEnabled) {
      _shakeDetector.start(() => setState(() => _tab = _MainTab.talk));
    } else {
      _shakeDetector.stop();
    }
  }

  /// Chrome 往復時にプロセスが生きたまま残るよう、osmWashabe と同様の無音キープアライブを使う。
  Future<void> _ensureKeepAliveForChrome() async {
    if (!Platform.isAndroid) return;
    await BackgroundAudioKeeper.instance.acquireChromeHandoff();
    _startedKeeperForChromeSession = true;
  }

  void _stopChromeKeepAliveIfOwned() {
    if (!_startedKeeperForChromeSession) return;
    _startedKeeperForChromeSession = false;
    unawaited(BackgroundAudioKeeper.instance.releaseChromeHandoff());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (!_awaitingPasteResult) return;

    // 復帰直後は UI を先に描画し、キープアライブの復旧は後から行う。
    // 遅延後も貼り付け待ち状態を再確認する（途中でリセットされた場合は何もしない）。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_awaitingPasteResult) return;
      if (_startedKeeperForChromeSession &&
          !BackgroundAudioKeeper.instance.isActuallyPlaying) {
        Future<void>.delayed(AppConstants.chromeKeepAliveRecoverDelay, () {
          if (!mounted ||
              !_awaitingPasteResult ||
              !_startedKeeperForChromeSession) {
            return;
          }
          unawaited(BackgroundAudioKeeper.instance.recoverIfNeeded());
        });
      }
    });
  }

  Future<void> _startRecording() async {
    if (_phase != _Phase.idle) return;
    final consented = await _ensureSpeechRecognitionConsent();
    if (!consented || !mounted || _phase != _Phase.idle) return;
    if (_errorMessage != null) {
      setState(() => _errorMessage = null);
    }

    if (!_voskWarmupStarted) {
      _voskWarmupStarted = true;
      AndroidVoskWarmup.schedule();
    }

    try {
      final started = await _stt.startRecording();
      if (!started) return;

      final now = DateTime.now();
      _sessionStartedAt ??= now;
      _currentPressStartedAt = now;
      // フリーモードはタップで録音を開始した後、指を離しても録音が続く（もう一度
      // タップするまで止まらない）ため、画面が自動ロックして録音が中断されない
      // よう画面消灯を防ぐ。固定秒数モードのカウントダウン中も同様に必要。
      unawaited(WakelockPlus.enable());
      setState(() {
        _phase = _Phase.recording;
        _errorMessage = null;
        _isSessionSaved = false;
      });
    } on SttFailure catch (e) {
      setState(() {
        _errorMessage = conversationErrorMessage(e, appSettings.language);
        _phase = _Phase.idle;
      });
    }
  }

  /// iOS/Androidで実装が異なる（iOSはApple Speech Recognitionのみ、
  /// AndroidはOSの音声認識→失敗時Voskフォールバック）ため、同意ダイアログの
  /// 文言もプライバシー画面と同じ粒度でプラットフォームごとに分ける。
  static String get _speechConsentBodyKey {
    if (Platform.isIOS) return '音声認識同意_本文_iOS';
    if (Platform.isAndroid) return '音声認識同意_本文_Android';
    return '音声認識同意_本文';
  }

  /// マイクやOS権限を要求する前に、録音音声の外部提供について明示同意を得る。
  /// 説明文の版が変わった場合は、既存ユーザーにも改めて表示する。
  Future<bool> _ensureSpeechRecognitionConsent() async {
    final prefs = appSettings.prefs;
    if (PrivacyConsent.hasCurrentSpeechConsent(prefs)) return true;
    final lang = appSettings.language;
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text('音声認識同意_タイトル'.tr(lang)),
        content: SingleChildScrollView(
          child: Text(_speechConsentBodyKey.tr(lang)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('同意しない'.tr(lang)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('同意する'.tr(lang)),
          ),
        ],
      ),
    );
    if (accepted != true) return false;
    await PrivacyConsent.grantSpeechConsent(prefs);
    return true;
  }

  /// 録音を終える（マイクをもう一度タップした、または固定秒数モードのカウントダウンが
  /// 終わった）ときに呼ぶ、ローカル完結版の録音停止処理。
  /// 端末内STTでまとめて文字起こしした結果を、これまでの認識結果に追記していくだけにする。
  Future<void> _stopRecordingAndAppendText() async {
    if (_phase != _Phase.recording) return;
    unawaited(WakelockPlus.disable());

    // 押下開始時刻・離した時刻は、これから始まる文字起こし待ち（数秒かかることがある）より
    // 前に確定させておく。文字起こし完了後の DateTime.now() を使うと、その待ち時間が
    // チャンク間の「沈黙」として誤カウントされてしまう。
    final pressStartedAt = _currentPressStartedAt ?? DateTime.now();
    final releasedAt = DateTime.now();
    setState(() {
      _phase = _Phase.processing;
      _transcribeProgress = null;
    });

    try {
      final recognized = (await _stt.stopAndTranscribe(
        onProgress: (value, phase) {
          if (!mounted) return;
          setState(() {
            _transcribeProgress = value;
            _transcribePhase = phase;
          });
        },
      )).trim();
      if (!mounted) return;
      setState(() {
        if (recognized.isNotEmpty) {
          _voiceInputText = _voiceInputText.isEmpty
              ? recognized
              : '$_voiceInputText $recognized';
          _voiceChunks.add(
            TranscriptChunk(text: recognized, recognizedAt: pressStartedAt),
          );
          _lastReleasedAt = releasedAt;
        }
        _phase = _Phase.idle;
        _transcribeProgress = null;
        _errorMessage = null;
      });
    } on SttFailure catch (e) {
      setState(() {
        _errorMessage = conversationErrorMessage(e, appSettings.language);
        _phase = _Phase.idle;
        _transcribeProgress = null;
      });
    }
  }

  /// 固定秒数モードでのマイクタップ処理。録音中でなければ録音開始＋カウントダウン開始、
  /// カウントダウン中なら一時停止／再開を切り替える。
  Future<void> _handleTimedMicTap() async {
    if (_phase == _Phase.recording) {
      _toggleCountdownPause();
      return;
    }
    await _startTimedRecording();
  }

  /// 録音開始と同時にカウントダウンを始め、0になったら
  /// （マイクをもう一度タップされるのを待たずに）自動で録音を止める。
  Future<void> _startTimedRecording() async {
    final totalSeconds = _durationMode.fixedSeconds;
    if (totalSeconds == null || _phase != _Phase.idle) return;

    // 画面消灯の防止（[WakelockPlus.enable]）は[_startRecording]内で共通して行う。
    await _startRecording();
    if (!mounted || _phase != _Phase.recording) return;

    setState(() {
      _countdownSecondsLeft = totalSeconds;
      _isCountdownPaused = false;
    });
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
      _onCountdownTick,
    );
  }

  void _onCountdownTick(Timer timer) {
    if (_phase != _Phase.recording) {
      timer.cancel();
      _countdownTimer = null;
      unawaited(WakelockPlus.disable());
      setState(() {
        _countdownSecondsLeft = null;
        _isCountdownPaused = false;
      });
      return;
    }
    final remaining = (_countdownSecondsLeft ?? 1) - 1;
    if (remaining <= 0) {
      timer.cancel();
      _countdownTimer = null;
      unawaited(WakelockPlus.disable());
      setState(() {
        _countdownSecondsLeft = null;
        _isCountdownPaused = false;
      });
      // osmWashabeと同じ、設定画面で選べるタイマー完了チャイムを鳴らす。
      unawaited(TimerAlert.playCompletion());
      unawaited(_stopRecordingAndAppendText());
    } else {
      setState(() => _countdownSecondsLeft = remaining);
    }
  }

  /// カウントダウン中のマイクタップで一時停止／再開を切り替える。一時停止中は
  /// 残り秒数の表示はそのままに、ボタンの色だけ録音中の赤から元の色に戻す
  /// （実際の録音自体は端末内STTの都合上、裏では継続する）。
  void _toggleCountdownPause() {
    if (_durationMode == _RecordingDurationMode.free) return;
    if (_countdownSecondsLeft == null) return;

    if (_countdownTimer != null) {
      _countdownTimer!.cancel();
      _countdownTimer = null;
      setState(() => _isCountdownPaused = true);
    } else {
      setState(() => _isCountdownPaused = false);
      _countdownTimer = Timer.periodic(
        const Duration(seconds: 1),
        _onCountdownTick,
      );
    }
  }

  /// マイク画面の待機中表示を、登録済みの声かけ文からランダムに選ぶ。
  void _pickRandomDisplayPrompt() {
    _displayPromptKey = AppStrings.randomTalkPromptKey();
  }

  /// 発話バッファ（テキスト・チャンク・セッション時刻）をクリアし、次の声かけ文を
  /// 選び直す。[_resetVoiceInput]（明示リセット）から呼ぶ。呼び出し側で
  /// [setState]に包むこと。
  void _clearConversationBuffer() {
    _voiceInputText = '';
    _voiceChunks.clear();
    _sessionStartedAt = null;
    _currentPressStartedAt = null;
    _lastReleasedAt = null;
    _pickRandomDisplayPrompt();
    _awaitingPasteResult = false;
    _isSessionSaved = false;
  }

  /// 録音・入力バッファをクリアし、気分選択画面（「元気してる？」の5段階選択）へ
  /// 戻る。バッファのクリアは、遷移アニメーション中に会話の残骸が一瞬見えるのを
  /// 防ぐための保険。
  void _resetVoiceInput() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    if (_phase == _Phase.recording) unawaited(WakelockPlus.disable());
    unawaited(_audioPlayer.stop());
    // 録音中（カウントダウン中含む）にリセットされた場合、ネイティブ側の録音セッションが
    // 生きたままだと次の[_startRecording]/[_startTimedRecording]が黙って失敗するため、
    // [_phase]をidleに戻す前にきちんと中断しておく。
    unawaited(_stt.cancelRecording());
    unawaited(_stt.clearLastRecording());
    setState(() {
      _clearConversationBuffer();
      _countdownSecondsLeft = null;
      _isCountdownPaused = false;
      _errorMessage = null;
      _phase = _Phase.idle;
      _isPlayingRecording = false;
    });
    _stopChromeKeepAliveIfOwned();
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  /// リセットボタンの押下ハンドラ。録音データが残っている場合は、誤タップで
  /// 消してしまわないよう確認アラートを挟む。録音データがなければそのまま
  /// [_resetVoiceInput]を呼び、気分選択画面へ即座に戻す。
  Future<void> _confirmResetVoiceInput() async {
    if (_stt.lastRecordingPath == null) {
      _resetVoiceInput();
      return;
    }
    final lang = appSettings.language;
    final confirmed = await showConfirmDialog(
      context,
      title: '会話をリセットしますか？'.tr(lang),
      message: '会話リセット_確認'.tr(lang),
      confirmLabel: 'リセット'.tr(lang),
      confirmColor: kRecordingColor,
      cancelLabel: 'キャンセル'.tr(lang),
    );
    if (confirmed) _resetVoiceInput();
  }

  /// [_voiceChunks]の内容とタイミングから、osmWashabeのJSST採点手法（[JsstScoringService]）
  /// を使って採点結果を算出する。
  /// osm_genkiには固定の持ち時間が無いため、「持ち時間」には実際にかかった時間
  /// （最初の録音開始〜最後に録音を止めた時刻）をそのまま使う。
  ScoringResult? _computeScoringResult() {
    final startedAt = _sessionStartedAt;
    if (_voiceChunks.isEmpty || startedAt == null) return null;

    // 最終チャンクの recognizedAt は押下"開始"時刻（[_stopRecordingAndAppendText]参照）
    // のため、発話枠の終点には使えない。実際に録音を止めた時刻を使う。
    final endedAt = _lastReleasedAt ?? _voiceChunks.last.recognizedAt;
    final elapsedSeconds = endedAt.difference(startedAt).inSeconds;
    return JsstScoringService.score(
      _voiceChunks,
      session: SpeechSessionContext(
        allottedSeconds: elapsedSeconds < 1 ? 1 : elapsedSeconds,
        startedAt: startedAt,
        endedAt: endedAt,
      ),
    );
  }

  /// 「聴き直す」ボタン押下時の処理。直近の録音を再生・停止をトグルする。
  Future<void> _togglePlayback() async {
    final path = _stt.lastRecordingPath;
    if (path == null) return;

    if (_isPlayingRecording) {
      await _audioPlayer.stop();
      if (mounted) setState(() => _isPlayingRecording = false);
      return;
    }

    setState(() => _isPlayingRecording = true);
    try {
      await _audioPlayer.play(DeviceFileSource(path));
    } catch (e, st) {
      debugPrint('osmGenki: playback failed: $e\n$st');
      if (mounted) setState(() => _isPlayingRecording = false);
    }
  }

  /// 発言テキストに、Chrome AIモードへ渡す指示文を付加したプロンプトを組み立てる。
  /// 表示言語（ja/en/vi）に応じてプロンプト全体と理由文の言語を切り替える。
  String _buildChromeAiPrompt(String userText) {
    return ChromeAiPrompts.recordingAnalysis(
      userText: userText,
      lang: appSettings.language,
    );
  }

  /// 「送信」タップ時の処理。送信前にユーザーへ同意確認を行ったうえで、外部AI
  /// APIには送らず、発言テキストに指示文を付けたプロンプトをクリップボードに
  /// コピーし、同じ内容をクエリに載せてChrome（既定ブラウザ）のAIモードを
  /// 自動で立ち上げるところまでを行う。
  /// 回答をコピーしてアプリに戻ってくるのは手動。
  /// ダイアログの「OK」を押すと、下部のボタンが「結果を貼り付け」に切り替わる。
  Future<void> _copyVoiceInputAndShowGuide() async {
    final lang = appSettings.language;
    final prompt = _buildChromeAiPrompt(_voiceInputText);
    final opened = await ChromeAiRoundTrip.ensureConsentAndOpen(
      context: context,
      prompt: prompt,
      lang: lang,
      titleKey: 'Google送信確認_タイトル_発言',
      bodyKey: 'Google送信確認_本文_発言',
      onAcquireKeepAlive: _ensureKeepAliveForChrome,
    );
    if (!mounted || !opened) return;
    setState(() => _awaitingPasteResult = true);
  }

  /// Chrome AIの解析結果と顔マークの起点から、保存する最終元気度（0〜10）を求める。
  /// 「ポジティブ度・ストレス度・疲労感・意欲」の4項目が揃っていればそれを優先し
  /// （[GenkiScoreCalculator.adjustmentFromDimensions]）、揃わなかった場合のみ
  /// 旧形式（AIが直接出す加減点／絶対値）にフォールバックする。
  int? _resolveGenkiScore({
    required int? baseline,
    required ChromeAiParsedResult parsed,
  }) {
    if (baseline != null && parsed.hasAllDimensions) {
      final adjustment = GenkiScoreCalculator.adjustmentFromDimensions(
        positivity: parsed.positivity!,
        stress: parsed.stress!,
        fatigue: parsed.fatigue!,
        motivation: parsed.motivation!,
      );
      return GenkiScoreCalculator.finalScore(
        baseline: baseline,
        adjustment: adjustment,
      );
    }
    if (baseline != null && parsed.genkiAdjustment != null) {
      return GenkiScoreCalculator.finalScore(
        baseline: baseline,
        adjustment: parsed.genkiAdjustment!,
      );
    }
    if (parsed.genkiAbsolute != null) {
      return parsed.genkiAbsolute!.clamp(
        GenkiScoreCalculator.minScore,
        GenkiScoreCalculator.maxScore,
      );
    }
    return null;
  }

  /// 「貼り付け」タップ時の処理。確認ダイアログは挟まず、クリップボードの内容を
  /// そのまま解析して即座に日記へ保存する。
  Future<void> _pasteAndSaveResult(BuildContext context) async {
    final lang = appSettings.language;
    final text = await ChromeAiRoundTrip.readClipboardText();
    if (!context.mounted) return;

    final parsed = ChromeAiResultParser.parse(text ?? '');
    final genkiScore = _resolveGenkiScore(
      baseline: widget.moodLevel?.genkiScore,
      parsed: parsed,
    );
    if (genkiScore == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('解析結果を読み取れなかった'.tr(lang))));
      return;
    }
    await _saveParsedResult(parsed, genkiScore: genkiScore);
  }

  /// パース済みの元気度・日本語評点・理由テキストを、最初の気分選択値とあわせて
  /// 1レコードとしてローカル（DiaryStorage）に追加保存する。
  /// 理由の箇条書きは[DiaryEntry.genkiReason]/[DiaryEntry.japaneseReason]に別で持たせ、
  /// [DiaryEntry.diaryText]には取れなかった場合の表示用フォールバックの一言サマリーを入れる。
  Future<void> _saveParsedResult(
    ChromeAiParsedResult parsed, {
    required int genkiScore,
  }) async {
    final lang = appSettings.language;
    final baseline = widget.moodLevel?.genkiScore;

    // osmWashabeのJSST採点（ルールベース1〜4→10点上の2/4/6/8）と
    // Chrome AIの日本語評点（1〜10、そのまま）を合成して保存する。
    final scoringResult = _computeScoringResult();
    final ruleBasedLevel1to4 = scoringResult == null
        ? null
        : JsstScoringService.combinedReferenceLevel(scoringResult);
    final japaneseLevel = JsstScoreCombiner.combine(
      ruleBasedLevel1to4: ruleBasedLevel1to4,
      chromeAiLevel1to10: parsed.japaneseLevel,
    );
    final japaneseLevelRuleBasedBand = JsstScoreCombiner.ruleBasedBandLabel(
      ruleBasedLevel1to4,
    );
    final fluencySnapshot =
        scoringResult != null && scoringResult.fluency.capturedSeconds > 0
        ? FluencySnapshot.fromAnalysis(scoringResult.fluency)
        : null;

    // 理由の箇条書きが取れなかった場合の表示用フォールバック（[DiaryCard]参照）。
    final diaryText = japaneseLevel == null
        ? 'Chrome AI解析結果_元気度のみ'.trFmt(lang, ['$genkiScore'])
        : 'Chrome AI解析結果'.trFmt(lang, ['$genkiScore', '$japaneseLevel']);

    await DiaryStorage.add(
      DiaryEntry(
        date: DateTime.now(),
        genkiScore: genkiScore,
        diaryText: diaryText,
        initialMoodScore: baseline,
        positivity: parsed.positivity,
        stress: parsed.stress,
        fatigue: parsed.fatigue,
        motivation: parsed.motivation,
        japaneseLevel: japaneseLevel,
        summary: parsed.summary,
        genkiReason: parsed.genkiReason,
        japaneseReason: parsed.japaneseReason,
        fluencySnapshot: fluencySnapshot,
        japaneseLevelRuleBasedBand: japaneseLevelRuleBasedBand,
        japaneseLevelRuleBased1to4: ruleBasedLevel1to4,
        recordedAt: _sessionStartedAt,
      ),
    );
    if (!mounted) return;
    // 録音データはここでは消さない。聴き直したくなったときのために、
    // リセットボタンが押されるまでそのまま残しておく。
    setState(() {
      _isSessionSaved = true;
      _awaitingPasteResult = false;
      _tab = _MainTab.diary;
    });
    _stopChromeKeepAliveIfOwned();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('結果を保存しました'.tr(lang))));
  }

  String get _mainText {
    final lang = appSettings.language;
    switch (_phase) {
      case _Phase.recording:
        return '録音中...'.tr(lang);
      case _Phase.processing:
        final progress = _transcribeProgress;
        if (progress == null) return '考え中...'.tr(lang);
        final label = _transcribePhase == TranscribePhase.preparingModel
            ? '文字起こし準備中...'.tr(lang)
            : '考え中...'.tr(lang);
        return '$label ${(progress * 100).round()}%';
      case _Phase.idle:
        // 声かけ文は日本語会話力向上アプリとしての「問いかけ」なので、表示言語に
        // 関わらず常に日本語で表示する。
        return _errorMessage ??
            (_voiceInputText.isEmpty
                ? _displayPromptKey.trJa
                : _voiceInputText);
    }
  }

  /// 待機中の声かけ文（意図した改行付き）を表示しているかどうか。
  bool get _isShowingTalkPrompt =>
      _phase == _Phase.idle && _errorMessage == null && _voiceInputText.isEmpty;

  /// 話した内容をそのまま表示しているかどうか。長文になりやすいので、
  /// 短い状態メッセージ（「録音中...」など）よりも小さいフォント・広い表示幅で見せる。
  bool get _isShowingVoiceInputText =>
      _phase == _Phase.idle &&
      _errorMessage == null &&
      _voiceInputText.isNotEmpty;

  /// 気分ヒント（アイコン）を表示するかどうか。認識テキストがまだ何もない、
  /// 待機中の初期状態でのみ表示する。
  bool get _showMoodHint =>
      widget.moodLevel != null &&
      _voiceInputText.isEmpty &&
      _phase == _Phase.idle;

  /// 右上「...」から開く、設定・ヘルプ用のポップアップメニュー（osmWashabeと同じ配置方式）。
  void _showMoreMenu(BuildContext context) {
    final box = _moreButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    final screen = MediaQuery.sizeOf(context);
    final lang = appSettings.language;

    showDialog<void>(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(ctx),
              behavior: HitTestBehavior.opaque,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            right: screen.width - offset.dx - size.width,
            top: offset.dy + size.height + 6,
            child: GenkiMoreActionsMenu(
              languageCode: lang,
              onSettings: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  fullscreenDismissRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                );
              },
              onHelp: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  fullscreenDismissRoute(
                    builder: (context) => const HelpPage(),
                  ),
                );
              },
              onExport: () {
                Navigator.pop(ctx);
                exportDiary(context);
              },
              onImport: () {
                Navigator.pop(ctx);
                importDiary(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// [•••]の長押しで開く、現在のタブに応じた使い方シート。
  void _showHelpSheet(BuildContext context) {
    final lang = appSettings.language;
    final (title, lines) = switch (_tab) {
      _MainTab.talk => ('話す'.tr(lang), _talkHelpLines(lang)),
      _MainTab.dashboard => ('振り返りダッシュボード'.tr(lang), _dashboardHelpLines(lang)),
      _MainTab.diary => ('ボイス日記一覧'.tr(lang), _diaryHelpLines(lang)),
    };
    GenkiHelpSheet.show(context, title: title, lines: lines);
  }

  List<GenkiHelpLine> _talkHelpLines(String lang) => [
    GenkiHelpLine(text: 'ヘルプ_録音_手順1'.tr(lang)),
    GenkiHelpLine(
      text: 'ヘルプ_録音_手順2'.tr(lang),
      icon: Icons.mic_none_rounded,
    ),
    GenkiHelpLine(text: 'ヘルプ_録音_手順3'.tr(lang)),
    GenkiHelpLine(
      text: 'ヘルプ_録音_手順3a'.tr(lang),
      icon: Icons.mic_none_rounded,
      indent: true,
    ),
    GenkiHelpLine(text: 'ヘルプ_録音_手順3b'.tr(lang), indent: true),
    GenkiHelpLine(text: 'ヘルプ_録音_手順4'.tr(lang), icon: Icons.send_rounded),
    GenkiHelpLine(text: 'ヘルプ_録音_手順5'.tr(lang)),
  ];

  List<GenkiHelpLine> _dashboardHelpLines(String lang) => [
    GenkiHelpLine(text: 'ヘルプ_ダッシュボード_見出しグラフ'.tr(lang), header: true),
    GenkiHelpLine(text: 'ヘルプ_ダッシュボード_グラフ1'.tr(lang), indent: true),
    GenkiHelpLine(text: 'ヘルプ_ダッシュボード_グラフ2'.tr(lang), indent: true),
    GenkiHelpLine(text: 'ヘルプ_ダッシュボード_グラフ3'.tr(lang), indent: true),
    GenkiHelpLine(text: 'ヘルプ_ダッシュボード_見出しカレンダー'.tr(lang), header: true),
    GenkiHelpLine(text: 'ヘルプ_ダッシュボード_カレンダー1'.tr(lang), indent: true),
  ];

  List<GenkiHelpLine> _diaryHelpLines(String lang) => [
    GenkiHelpLine(text: 'ヘルプ_日記_手順1'.tr(lang)),
    GenkiHelpLine(text: 'ヘルプ_日記_手順2'.tr(lang), icon: Icons.send_rounded),
    GenkiHelpLine(text: 'ヘルプ_日記_手順3'.tr(lang)),
  ];

  Widget _buildTalkBody(String lang, Color scene, Color fg) {
    return Column(
      children: [
        _RecordingDurationSelector(
          mode: _durationMode,
          enabled: _phase == _Phase.idle,
          foreground: fg,
          onChanged: (mode) => setState(() {
            _durationMode = mode;
            _lastDurationMode = mode;
          }),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            reverse: true,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_showMoodHint) ...[
                  Icon(widget.moodLevel!.icon, color: fg, size: 112),
                  const SizedBox(height: 12),
                ],
                if (_isShowingTalkPrompt)
                  SizedBox(
                    width: double.infinity,
                    child: _FitLinePromptText(
                      text: _mainText,
                      color: fg,
                      maxFontSize: 32,
                    ),
                  )
                else
                  Text(
                    _mainText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: fg,
                      fontSize: _isShowingVoiceInputText ? 22 : 32,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: _MicButton(
                phase: _phase,
                isFreeMode: _durationMode == _RecordingDurationMode.free,
                countdownSecondsLeft: _countdownSecondsLeft,
                isCountdownPaused: _isCountdownPaused,
                transcribeProgress: _transcribeProgress,
                onPressStart: _startRecording,
                onPressEnd: _stopRecordingAndAppendText,
                onTimedTap: _handleTimedMicTap,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                children: [
                  Expanded(
                    child: Tooltip(
                      message: (_isPlayingRecording ? '停止' : '聴き直す').tr(lang),
                      child: IconButton(
                        onPressed: _stt.lastRecordingPath == null
                            ? null
                            : _togglePlayback,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Icon(
                          _isPlayingRecording
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                          size: 40,
                          color: _stt.lastRecordingPath == null
                              ? Colors.transparent
                              : appAppearance.accentColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Tooltip(
                      message: 'リセット'.tr(lang),
                      child: IconButton(
                        onPressed: _confirmResetVoiceInput,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Icon(Icons.refresh_rounded, size: 40, color: fg),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Tooltip(
                      message: (_awaitingPasteResult ? '貼り付け' : '送信').tr(lang),
                      child: IconButton(
                        onPressed: _voiceInputText.isEmpty || _isSessionSaved
                            ? null
                            : () => _awaitingPasteResult
                                  ? _pasteAndSaveResult(context)
                                  : _copyVoiceInputAndShowGuide(),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: Icon(
                          _awaitingPasteResult
                              ? Icons.content_paste_go_rounded
                              : Icons.send_rounded,
                          size: 40,
                          color: (_voiceInputText.isEmpty || _isSessionSaved)
                              ? Colors.transparent
                              : (_awaitingPasteResult
                                    ? kPasteReadyColor
                                    : appAppearance.accentColor),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = appSettings.language;
    final scene = appAppearance.sceneColor;
    final effectiveScheme = appAppearance.effectiveColorScheme;
    final fg = appAppearance.foregroundOn(scene);

    return Scaffold(
      backgroundColor: scene,
      body: Stack(
        fit: StackFit.expand,
        children: [
          AppearanceBackgroundLayer(
            sceneColor: scene,
            colorScheme: effectiveScheme,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                children: [
                  GenkiToolbar(
                    moreButtonKey: _moreButtonKey,
                    scene: scene,
                    foreground: fg,
                    talkSelected: _tab == _MainTab.talk,
                    dashboardSelected: _tab == _MainTab.dashboard,
                    diarySelected: _tab == _MainTab.diary,
                    talkTooltip: '話す'.tr(lang),
                    dashboardTooltip: '振り返りダッシュボード'.tr(lang),
                    diaryTooltip: 'ボイス日記一覧'.tr(lang),
                    moreTooltip: 'その他'.tr(lang),
                    onTalk: () => setState(() => _tab = _MainTab.talk),
                    onDashboard: () =>
                        setState(() => _tab = _MainTab.dashboard),
                    onDiary: () => setState(() => _tab = _MainTab.diary),
                    onMore: () => _showMoreMenu(context),
                    onMoreLongPress: () => _showHelpSheet(context),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: IndexedStack(
                      index: _tab.index,
                      children: [
                        _buildTalkBody(lang, scene, fg),
                        const DashboardPage(),
                        const DiaryListPage(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MicButton extends StatefulWidget {
  const _MicButton({
    required this.phase,
    required this.isFreeMode,
    required this.countdownSecondsLeft,
    required this.isCountdownPaused,
    required this.transcribeProgress,
    required this.onPressStart,
    required this.onPressEnd,
    required this.onTimedTap,
  });

  final _Phase phase;

  /// フリーモード（タップで録音開始／終了をトグル）かどうか。falseなら固定秒数モード
  /// （タップしてカウントダウン録音）。
  final bool isFreeMode;

  /// 固定秒数モードでのカウントダウン残り秒数。表示中でなければnull。
  final int? countdownSecondsLeft;

  /// カウントダウンをタップで一時停止しているかどうか（固定秒数モードのみ）。
  final bool isCountdownPaused;

  /// osmWashabeと同じ、Android文字起こし中の進捗（0.0〜1.0）。不明ならnull
  /// （その間はぐるぐる回るだけの不確定表示にフォールバックする）。
  final double? transcribeProgress;
  final VoidCallback onPressStart;
  final VoidCallback onPressEnd;
  final VoidCallback onTimedTap;

  @override
  State<_MicButton> createState() => _MicButtonState();
}

/// タップ判定は[GestureDetector]ではなく、[Listener]で生のポインタイベントを
/// 直接見て自前で行う。実機（特にAndroid）で、祖先や兄弟に別のrecognizer
/// （スワイプ検出など）が存在すると、[GestureDetector]のrecognizerは必ず
/// ジェスチャーアリーナに参加するため、わずかな移動だけでそちらが「勝ち」を
/// 宣言してしまうことがある。[Listener]はアリーナに参加しないため、アプリ内
/// のどんなジェスチャーとも競合しない。
///
/// フリーモードは「タップで録音開始→もう一度タップで録音終了」のトグル方式に
/// している。かつては長押しで録音していたが、実機・特にAndroidで指を押し込んだ
/// りわずかに動かしただけで長押しがキャンセル扱いになり、録音が途中で誤って
/// 切れてしまう不具合が報告されたため、誤作動の起きにくいタップ2回方式に変更した。
class _MicButtonState extends State<_MicButton> {
  int? _activePointer;

  void _onPointerDown(PointerDownEvent event) {
    if (_activePointer != null) return;
    _activePointer = event.pointer;
  }

  void _onPointerUp(PointerUpEvent event) {
    if (event.pointer != _activePointer) return;
    _finishTracking(cancelled: false);
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (event.pointer != _activePointer) return;
    _finishTracking(cancelled: true);
  }

  void _finishTracking({required bool cancelled}) {
    _activePointer = null;
    // OS都合でキャンセルされた場合はタップ扱いにしない（誤って録音の
    // 開始／終了が切り替わらないようにする）。
    if (cancelled) return;

    if (widget.isFreeMode) {
      // 録音中でなければ開始、録音中なら終了、とタップのたびに切り替える。
      if (widget.phase == _Phase.recording) {
        widget.onPressEnd();
      } else if (widget.phase == _Phase.idle) {
        widget.onPressStart();
      }
      return;
    }
    // 固定秒数モードはタップのみ（長押しの概念はない）。
    widget.onTimedTap();
  }

  @override
  Widget build(BuildContext context) {
    final phase = widget.phase;
    final isFreeMode = widget.isFreeMode;
    final countdownSecondsLeft = widget.countdownSecondsLeft;
    final isCountdownPaused = widget.isCountdownPaused;
    final transcribeProgress = widget.transcribeProgress;
    final isRecording = phase == _Phase.recording;
    final isProcessing = phase == _Phase.processing;
    // ボタン自体の塗りはシーンで調整しない、テーマそのもののアクセント色を使う
    // （WeeklyAdviceCardのボタンと同じ「単色塗り＋foregroundOnで文字色を決める」方式）。
    // カウントダウン一時停止中は「録音していない見た目」に戻すため、赤ではなくアクセント色にする。
    final showAsRecordingColor = isRecording && !isCountdownPaused;
    final fillColor = showAsRecordingColor
        ? kRecordingColor
        : appAppearance.accentColor;

    final Widget icon;
    if (isProcessing) {
      icon = Padding(
        padding: const EdgeInsets.all(34),
        child: CircularProgressIndicator(
          value: transcribeProgress?.clamp(0.02, 1.0),
          color: AppColors.current.onAccent,
          strokeWidth: 3,
        ),
      );
    } else if (!isFreeMode && countdownSecondsLeft != null) {
      // 固定秒数モードで録音中：マイクマークの代わりに残り秒数（数字のみ）を出す。
      icon = Text(
        '$countdownSecondsLeft',
        style: TextStyle(
          color: AppColors.current.onAccent,
          fontSize: 44,
          fontWeight: FontWeight.w700,
        ),
      );
    } else {
      icon = Icon(
        isRecording ? Icons.mic : Icons.mic_none_rounded,
        color: AppColors.current.onAccent,
        size: 60,
      );
    }

    final lang = appSettings.language;
    final semanticsLabel = isProcessing
        ? '録音中...'.tr(lang)
        : isRecording
        ? '録音中...'.tr(lang)
        : '話す'.tr(lang);

    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 120,
          height: 120,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: fillColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: icon,
        ),
      ),
    );
  }
}

/// マイク画面上部の録音モード選択（フリー／30秒／45秒／60秒）。
/// Material の[SegmentedButton]は選択アイコン分の余白を確保してしまい、
/// 全角3文字の「フリー」だけ折り返す崩れが出たため、自前のピル型ボタン列にする。
class _RecordingDurationSelector extends StatelessWidget {
  const _RecordingDurationSelector({
    required this.mode,
    required this.enabled,
    required this.foreground,
    required this.onChanged,
  });

  final _RecordingDurationMode mode;

  /// 録音・処理中はモード変更を無効にする。
  final bool enabled;
  final Color foreground;
  final ValueChanged<_RecordingDurationMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final lang = appSettings.language;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.5,
      child: IgnorePointer(
        ignoring: !enabled,
        child: Row(
          children: [
            for (final value in _RecordingDurationMode.values) ...[
              if (value != _RecordingDurationMode.values.first)
                const SizedBox(width: 8),
              Expanded(
                child: _DurationOptionButton(
                  label: value.displaySeconds,
                  icon: value.displaySeconds == null
                      ? Icons.all_inclusive_rounded
                      : null,
                  tooltip: value.labelKey.tr(lang),
                  selected: value == mode,
                  foreground: foreground,
                  onTap: () => onChanged(value),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DurationOptionButton extends StatelessWidget {
  const _DurationOptionButton({
    this.label,
    this.icon,
    required this.tooltip,
    required this.selected,
    required this.foreground,
    required this.onTap,
  }) : assert(label != null || icon != null);

  /// 秒数モードの表示（例: "30"）。フリーモードでは null（[icon]を使う）。
  final String? label;

  /// フリーモードの表示アイコン。秒数モードでは null（[label]を使う）。
  final IconData? icon;
  final String tooltip;
  final bool selected;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final contentColor = selected
        ? appAppearance.foregroundOn(appAppearance.accentColor)
        : foreground;

    return Semantics(
      label: tooltip,
      button: true,
      selected: selected,
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: selected ? appAppearance.accentColor : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: foreground.withValues(alpha: 0.4)),
            ),
            alignment: Alignment.center,
            child: icon != null
                ? Icon(icon, color: contentColor, size: 18)
                // 全角ラベルが幅の狭い端末でも折り返さず、必ず1行に収まるよう縮小表示する。
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label!,
                      maxLines: 1,
                      style: TextStyle(
                        color: contentColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// 改行（\n）で区切られた各行を、折り返さず1行に収めるようフォントサイズを調整して表示する。
class _FitLinePromptText extends StatelessWidget {
  const _FitLinePromptText({
    required this.text,
    required this.color,
    this.maxFontSize = 32,
  });

  final String text;
  final Color color;
  final double maxFontSize;

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final style = TextStyle(
      color: color,
      fontSize: maxFontSize,
      fontWeight: FontWeight.w600,
      height: 1.25,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        if (!maxWidth.isFinite || maxWidth <= 0) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final line in lines)
                Text(line, textAlign: TextAlign.center, style: style),
            ],
          );
        }

        return SizedBox(
          width: maxWidth,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final line in lines)
                  Text(
                    line,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    style: style,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
