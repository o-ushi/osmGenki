import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/genki_score_calculator.dart';
import '../theme/app_colors.dart';
import 'metric_row.dart';
import 'reason_bullet_list.dart';

/// 元気度バッジの長押しで開く「スコアの内訳」。顔マークの起点・加減点・
/// 最終元気度と、理由の箇条書きを表示する。
Future<void> showGenkiScoreBreakdownDialog({
  required BuildContext context,
  required String lang,
  required int genkiScore,
  int? initialMoodScore,
  int? positivity,
  int? stress,
  int? fatigue,
  int? motivation,
  String? genkiReason,
}) {
  final adjustment = initialMoodScore == null
      ? null
      : genkiScore - initialMoodScore;

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('スコアの内訳'.tr(lang)),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (initialMoodScore != null) ...[
              MetricRow(label: '元気度の起点'.tr(lang), value: '$initialMoodScore'),
              if (positivity != null)
                MetricRow(label: 'ポジティブ度'.tr(lang), value: '$positivity'),
              if (stress != null)
                MetricRow(label: 'ストレス度'.tr(lang), value: '$stress'),
              if (fatigue != null)
                MetricRow(label: '疲労感'.tr(lang), value: '$fatigue'),
              if (motivation != null)
                MetricRow(label: '意欲'.tr(lang), value: '$motivation'),
              if (adjustment != null)
                MetricRow(
                  label: '加減点'.tr(lang),
                  value: GenkiScoreCalculator.formatAdjustment(
                    adjustment,
                    lang,
                  ),
                ),
            ],
            MetricRow(label: '最終元気度'.tr(lang), value: '$genkiScore'),
            if (genkiReason != null) ...[
              const SizedBox(height: 12),
              Text(
                '理由'.tr(lang),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              ReasonBulletList(
                text: genkiReason,
                color: AppColors.current.textOnCardPrimary,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text('OK'.tr(lang)),
        ),
      ],
    ),
  );
}
