import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../app_globals.dart';
import '../models/jsst_scoring_models.dart';
import '../services/diary_storage.dart';
import '../theme/app_colors.dart';
import 'fluency_metrics_dialog.dart';
import 'genki_frame_card.dart';
import 'genki_score_breakdown_dialog.dart';
import 'reason_bullet_list.dart';

class DiaryCard extends StatelessWidget {
  const DiaryCard({super.key, required this.entry});

  final DiaryEntry entry;

  @override
  Widget build(BuildContext context) {
    final frameStyle = appAppearance.resolvedFrameStyle();
    // Chrome AIの解析結果から理由の箇条書きが取れているエントリだけ、
    // バッジ＋箇条書きの構造化レイアウトにする。取れなかった旧形式・簡易サマリーの
    // エントリは、これまで通りdiaryTextをそのまま表示する。
    final hasStructuredReasons =
        entry.genkiReason != null || entry.japaneseReason != null;

    return GenkiFrameCard(
      style: frameStyle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${AppStrings.dateLabel(entry.date, appSettings.language)} '
            '${entry.recordedTimeLabel}',
            style: TextStyle(
              color: frameStyle.readablePrimaryText,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            // ベトナム語の日付表記（例: "Ngày 6 tháng 7 năm 2026"）は1行に収まらず
            // 末尾（年・時刻）が欠けることがあるため、2行まで許容する。
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (entry.summary != null) ...[
            const SizedBox(height: 8),
            Text(
              entry.summary!,
              style: TextStyle(
                color: frameStyle.readableSecondaryText,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 10),
          GenkiBadge(
            score: entry.genkiScore,
            initialMoodScore: entry.initialMoodScore,
            positivity: entry.positivity,
            stress: entry.stress,
            fatigue: entry.fatigue,
            motivation: entry.motivation,
            genkiReason: entry.genkiReason,
          ),
          if (entry.genkiReason != null) ...[
            const SizedBox(height: 6),
            ReasonBulletList(
              text: entry.genkiReason!,
              color: frameStyle.readableSecondaryText,
            ),
          ],
          if (entry.japaneseLevel != null) ...[
            const SizedBox(height: 14),
            JapaneseLevelBadge(
              level: entry.japaneseLevel!,
              ruleBasedLevelBand: entry.japaneseLevelRuleBasedBand,
              ruleBasedLevel1to4: entry.japaneseLevelRuleBased1to4,
              fluencySnapshot: entry.fluencySnapshot,
            ),
            if (entry.japaneseReason != null) ...[
              const SizedBox(height: 6),
              ReasonBulletList(
                text: entry.japaneseReason!,
                color: frameStyle.readableSecondaryText,
              ),
            ],
          ],
          if (!hasStructuredReasons) ...[
            const SizedBox(height: 10),
            Text(
              entry.diaryText,
              style: TextStyle(
                color: frameStyle.readableSecondaryText,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 青地に白文字の塗りつぶしバッジ。元気度・日本語評点で共通の見た目にする。
class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: appAppearance.accentColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.current.onAccent,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class GenkiBadge extends StatelessWidget {
  const GenkiBadge({
    super.key,
    required this.score,
    this.initialMoodScore,
    this.positivity,
    this.stress,
    this.fatigue,
    this.motivation,
    this.genkiReason,
  });

  final int score;

  /// 会話開始時に選んだ顔マークの元気度起点（1/3/5/7/9）。旧エントリ・気分選択を
  /// 経由しない保存ではnull。スコア内訳ダイアログで加減点の計算に使う。
  final int? initialMoodScore;

  /// 元気度の内訳4項目（各0〜4）。旧エントリ・4項目が取れなかった場合はnull。
  final int? positivity;
  final int? stress;
  final int? fatigue;
  final int? motivation;
  final String? genkiReason;

  @override
  Widget build(BuildContext context) {
    final lang = appSettings.language;
    void showBreakdown() => showGenkiScoreBreakdownDialog(
      context: context,
      lang: lang,
      genkiScore: score,
      initialMoodScore: initialMoodScore,
      positivity: positivity,
      stress: stress,
      fatigue: fatigue,
      motivation: motivation,
      genkiReason: genkiReason,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onLongPress: showBreakdown,
          child: _ScoreBadge(text: '${'元気度'.tr(lang)}：$score'),
        ),
        IconButton(
          onPressed: showBreakdown,
          icon: Icon(
            Icons.info_outline,
            size: 18,
            color: appAppearance.mutedOn(AppColors.current.cardFill),
          ),
          tooltip: 'スコアの内訳'.tr(lang),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
      ],
    );
  }
}

/// JSSTと同じ1〜10スケールの日本語評点バッジ。
class JapaneseLevelBadge extends StatelessWidget {
  const JapaneseLevelBadge({
    super.key,
    required this.level,
    this.ruleBasedLevelBand,
    this.ruleBasedLevel1to4,
    this.fluencySnapshot,
  });

  final int level;

  /// Chrome AIを混ぜない、osmWashabeのルールベース判定そのままの帯域ラベル
  /// （「1〜2」「3〜4」「5〜6」「7〜」）。スコア内訳ダイアログにはバッジの合成値
  /// ではなくこちらを表示する。
  final String? ruleBasedLevelBand;

  /// [ruleBasedLevelBand]の元になったアプリ内参照レベル（1〜4）。
  /// キャリブレーションカード（開発者モードのみ表示）で使う。
  final int? ruleBasedLevel1to4;
  final FluencySnapshot? fluencySnapshot;

  @override
  Widget build(BuildContext context) {
    final lang = appSettings.language;
    return GestureDetector(
      onLongPress: () => showFluencyMetricsDialog(
        context: context,
        lang: lang,
        level: ruleBasedLevelBand,
        ruleBasedLevel1to4: ruleBasedLevel1to4,
        snapshot: fluencySnapshot,
      ),
      child: _ScoreBadge(text: '${'会話力'.tr(lang)}：$level'),
    );
  }
}
