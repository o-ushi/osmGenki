import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../app_globals.dart';
import '../services/background_audio_keeper.dart';
import '../services/chrome_ai_prompts.dart';
import '../services/chrome_ai_round_trip.dart';
import '../services/diary_review_storage.dart';
import '../services/diary_storage.dart';
import '../theme/app_colors.dart';
import '../widgets/confirm_delete_dialog.dart';
import '../widgets/delete_swipe_background.dart';
import '../widgets/diary_card.dart';
import '../widgets/diary_review_dialog.dart';
import '../widgets/swipe_down_to_dismiss.dart';
import 'diary_review_list_page.dart';

class DiaryListPage extends StatefulWidget {
  const DiaryListPage({super.key});

  @override
  State<DiaryListPage> createState() => _DiaryListPageState();
}

class _DiaryListPageState extends State<DiaryListPage> {
  late Future<List<DiaryEntry>> _entriesFuture;
  late Future<List<DiaryReview>> _reviewsFuture;

  /// 「日記を見てもらう」の結果貼り付け待ちかどうか（送信/貼り付けの2状態トグル、
  /// main.dartの会話送信フローと同じ方式）。
  bool _awaitingReviewPaste = false;

  /// このページがChromeキープアライブを開始したか（main.dartと同じ、参照
  /// カウント付きBackgroundAudioKeeperの所有権フラグ）。
  bool _startedKeeperForReviewSession = false;

  @override
  void initState() {
    super.initState();
    _reload();
    appSettings.addListener(_onSettingsChanged);
    DiaryStorage.changes.addListener(_onDiaryChanged);
    DiaryReviewStorage.changes.addListener(_onReviewsChanged);
  }

  @override
  void dispose() {
    appSettings.removeListener(_onSettingsChanged);
    DiaryStorage.changes.removeListener(_onDiaryChanged);
    DiaryReviewStorage.changes.removeListener(_onReviewsChanged);
    _stopReviewKeepAliveIfOwned();
    super.dispose();
  }

  Future<void> _ensureKeepAliveForReview() async {
    if (!Platform.isAndroid) return;
    await BackgroundAudioKeeper.instance.acquireChromeHandoff();
    _startedKeeperForReviewSession = true;
  }

  void _stopReviewKeepAliveIfOwned() {
    if (!_startedKeeperForReviewSession) return;
    _startedKeeperForReviewSession = false;
    unawaited(BackgroundAudioKeeper.instance.releaseChromeHandoff());
  }

  void _reload() {
    _entriesFuture = DiaryStorage.loadAll();
    _reviewsFuture = DiaryReviewStorage.loadAll();
  }

  void _onSettingsChanged() => setState(() {});

  void _onDiaryChanged() => setState(_reload);

  void _onReviewsChanged() => setState(_reload);

  /// 「日記を見てもらう」タップ時の処理。送信前にユーザーへ同意確認を行った
  /// うえで、ホーム画面の送信と同じ方式：プロンプトをコピーしつつ、
  /// Chrome AIモードを開く。
  Future<void> _requestDiaryReview(List<DiaryEntry> entries) async {
    if (entries.isEmpty) return;
    final lang = appSettings.language;
    final prompt = ChromeAiPrompts.diaryReview(entries, lang);
    final opened = await ChromeAiRoundTrip.ensureConsentAndOpen(
      context: context,
      prompt: prompt,
      lang: lang,
      titleKey: 'Google送信確認_タイトル_日記',
      bodyKey: 'Google送信確認_本文_日記',
      onAcquireKeepAlive: _ensureKeepAliveForReview,
    );
    if (!mounted || !opened) return;
    setState(() => _awaitingReviewPaste = true);
  }

  /// 「貼り付け」タップ時の処理。クリップボードの内容をアドバイスとして保存し、
  /// そのまま表示する（数値抽出などは行わない読み物としてそのまま[DiaryReviewStorage]へ）。
  Future<void> _pasteDiaryReviewResult(BuildContext context) async {
    final lang = appSettings.language;
    final text = await ChromeAiRoundTrip.readClipboardText();
    if (!context.mounted) return;

    if (text == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('アドバイスを読み取れなかった'.tr(lang))));
      return;
    }

    setState(() => _awaitingReviewPaste = false);
    _stopReviewKeepAliveIfOwned();

    await DiaryReviewStorage.add(DiaryReview(date: DateTime.now(), text: text));
    if (!context.mounted) return;

    await showDiaryReviewDialog(context: context, lang: lang, text: text);
  }

  @override
  Widget build(BuildContext context) {
    final lang = appSettings.language;
    final scene = appAppearance.sceneColor;
    final fg = appAppearance.foregroundOn(scene);

    return FutureBuilder<List<Object?>>(
      future: Future.wait([_entriesFuture, _reviewsFuture]),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Center(child: CircularProgressIndicator(color: fg));
        }

        final entries = (snapshot.data?[0] as List<DiaryEntry>?) ?? const [];
        final reviews = (snapshot.data?[1] as List<DiaryReview>?) ?? const [];

        return Column(
          children: [
            _DiaryReviewButton(
              lang: lang,
              enabled: entries.isNotEmpty,
              awaitingPaste: _awaitingReviewPaste,
              hasReviews: reviews.isNotEmpty,
              onTap: () => _awaitingReviewPaste
                  ? _pasteDiaryReviewResult(context)
                  : _requestDiaryReview(entries),
              onViewTap: () => Navigator.of(context).push(
                fullscreenDismissRoute(
                  builder: (context) => const DiaryReviewListPage(),
                ),
              ),
            ),
            Expanded(
              child: entries.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'まだ日記がないよ。\n話してみてね。'.tr(lang),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: fg.withValues(alpha: 0.85),
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return Dismissible(
                          key: ValueKey(entry.date.toIso8601String()),
                          direction: DismissDirection.endToStart,
                          background: const DeleteSwipeBackground(),
                          confirmDismiss: (_) => confirmDelete(
                            context,
                            lang: lang,
                            bodyKey: '日記削除_確認',
                          ),
                          onDismissed: (_) => DiaryStorage.remove(entry),
                          child: DiaryCard(entry: entry),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// ツールバー直下の「診断」（日記を見てもらう/貼り付けトグル）＋「閲覧」ボタン。
class _DiaryReviewButton extends StatelessWidget {
  const _DiaryReviewButton({
    required this.lang,
    required this.enabled,
    required this.awaitingPaste,
    required this.hasReviews,
    required this.onTap,
    required this.onViewTap,
  });

  final String lang;
  final bool enabled;
  final bool awaitingPaste;

  /// 閲覧できる診断結果が1件以上あるか。あれば「閲覧」ボタンを青地に白アイコンで強調する。
  final bool hasReviews;
  final VoidCallback onTap;
  final VoidCallback onViewTap;

  @override
  Widget build(BuildContext context) {
    // マイク画面下部の再生/リセット/送信ボタンと同じ形状・サイズ（アイコンのみ、
    // vertical:14のパディング、アイコンサイズ30）に揃える。
    final diagnoseBackground = awaitingPaste
        ? kPasteReadyColor
        : appAppearance.accentColor;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Tooltip(
                  message: (awaitingPaste ? '貼り付け' : '診断').tr(lang),
                  child: FilledButton(
                    onPressed: enabled ? onTap : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: diagnoseBackground,
                      foregroundColor: awaitingPaste
                          ? AppColors.current.onAccent
                          : appAppearance.foregroundOn(diagnoseBackground),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Icon(
                      awaitingPaste
                          ? Icons.content_paste_go_rounded
                          : Icons.send_rounded,
                      size: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Tooltip(
                  message: '閲覧'.tr(lang),
                  child: hasReviews
                      ? FilledButton(
                          onPressed: onViewTap,
                          style: FilledButton.styleFrom(
                            backgroundColor: appAppearance.accentColor,
                            foregroundColor: AppColors.current.onAccent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Icon(Icons.list_alt_rounded, size: 30),
                        )
                      : OutlinedButton(
                          onPressed: onViewTap,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Icon(Icons.list_alt_rounded, size: 30),
                        ),
                ),
              ),
            ],
          ),
          if (awaitingPaste) ...[
            const SizedBox(height: 8),
            Text(
              'ヒント_日記レビュー貼り付け待ち'.tr(lang),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: appAppearance
                    .foregroundOn(appAppearance.sceneColor)
                    .withValues(alpha: 0.85),
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
