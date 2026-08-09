import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../app_globals.dart';
import '../models/jsst_scoring_models.dart';
import '../theme/app_colors.dart';
import 'calibration_section.dart';
import 'metric_row.dart';

Future<void> showFluencyMetricsDialog({
  required BuildContext context,
  required String lang,
  // osmWashabeのルールベース判定そのままの帯域ラベル（「1〜2」「3〜4」「5〜6」「7〜」、
  // Chrome AIとの合成前）。旧エントリはnull。
  String? level,
  // [level]の元になった、アプリ内参照レベル（1〜4）。キャリブレーションカード（開発者
  // モードのみ表示）で使う。旧エントリはnull。
  int? ruleBasedLevel1to4,
  FluencySnapshot? snapshot,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('スコアの内訳'.tr(lang)),
      content: SingleChildScrollView(
        child: snapshot == null
            ? Text('スコア内訳_データなし'.tr(lang))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (level != null) ...[
                    Text(
                      'JSST $level'.tr(lang),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                  Text(
                    'スコア内訳_説明'.tr(lang),
                    style: TextStyle(
                      color: AppColors.current.textOnCardSecondary,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '時間の使い方'.tr(lang),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  MetricRow(
                    label: '発話枠'.tr(lang),
                    value: '${snapshot.allottedSeconds}${'秒'.tr(lang)}',
                  ),
                  MetricRow(
                    label: '発話文字数'.tr(lang),
                    value: '${snapshot.spokenCharacterCount}',
                  ),
                  MetricRow(
                    label: '枠あたりの発話量'.tr(lang),
                    value:
                        '${snapshot.charactersPerAllottedMinute.round()}${'字/分'.tr(lang)}',
                  ),
                  MetricRow(
                    label: '推定発話時間'.tr(lang),
                    value:
                        '${snapshot.estimatedSpeechSeconds.round()}${'秒'.tr(lang)}',
                  ),
                  MetricRow(
                    label: '時間の利用率'.tr(lang),
                    value: '${(snapshot.timeUtilization * 100).round()}%',
                  ),
                  MetricRow(
                    label: '推定沈黙の割合'.tr(lang),
                    value: '${(snapshot.silenceRatio * 100).round()}%',
                  ),
                  MetricRow(
                    label: '長い沈黙（4秒以上）'.tr(lang),
                    value: '${snapshot.longPauseCount}${'回'.tr(lang)}',
                  ),
                  const SizedBox(height: 12),
                  _MetricDefinition(
                    title: '時間の利用率'.tr(lang),
                    body: 'スコア内訳_時間の利用率_定義'.tr(lang),
                  ),
                  const SizedBox(height: 10),
                  _MetricDefinition(
                    title: '推定沈黙の割合'.tr(lang),
                    body: 'スコア内訳_推定沈黙の割合_定義'.tr(lang),
                  ),
                  if (appSettings.developerModeEnabled) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 4),
                    CalibrationSection(
                      appLevel: ruleBasedLevel1to4,
                      lang: lang,
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

class _MetricDefinition extends StatelessWidget {
  const _MetricDefinition({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.current.textOnCardSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: muted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 4),
        Text(body, style: TextStyle(color: muted, fontSize: 12, height: 1.45)),
      ],
    );
  }
}
