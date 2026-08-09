import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../app_globals.dart';
import '../services/jsst_calibration_service.dart';
import '../services/jsst_score_combiner.dart';
import '../theme/app_colors.dart';

/// JSST採点キャリブレーション（開発者モード専用）。
/// osmWashabe（lib/views/practice/scoring_result_view.dart の `_CalibrationCard`）から移植し、
/// 「スコアの内訳」ダイアログの一番下に表示する。補正係数は設定画面の「開発者向け」欄でも確認できる
/// （[AppSettings.calibrationBias]参照）。
class CalibrationSection extends StatefulWidget {
  const CalibrationSection({
    super.key,
    required this.appLevel,
    required this.lang,
  });

  /// [JsstScoringService.combinedReferenceLevel]の値そのまま（1〜4）。
  /// 発話が短すぎる等で参考レベルが算出できなかった場合はnull。
  final int? appLevel;
  final String lang;

  @override
  State<CalibrationSection> createState() => _CalibrationSectionState();
}

class _CalibrationSectionState extends State<CalibrationSection> {
  late int _selectedJsstLevel;

  @override
  void initState() {
    super.initState();
    final appLevel = widget.appLevel;
    _selectedJsstLevel = appLevel != null
        ? JsstCalibrationService.internalToJsstDefault(appLevel)
        : 5;
  }

  void _applyCalibration() {
    final appLevel = widget.appLevel;
    if (appLevel == null) return;
    final userInternal = JsstCalibrationService.jsstLevelToInternal(
      _selectedJsstLevel,
    );
    final newBias = JsstCalibrationService.updateBias(
      currentBias: appSettings.calibrationBias,
      userInternalLevel: userInternal,
      appInternalLevel: appLevel,
    );
    appSettings.calibrationBias = newBias;
    appSettings.calibrationSampleCount = appSettings.calibrationSampleCount + 1;
    setState(() {});
  }

  void _resetCalibration() {
    appSettings.clearCalibration();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final bias = appSettings.calibrationBias;
    final sampleCount = appSettings.calibrationSampleCount;
    final appLevel = widget.appLevel;
    final adjustedLevel = JsstCalibrationService.adjustedLevel(appLevel, bias);
    final biasLabel = JsstCalibrationService.biasLabel(bias);
    final biasSign = bias >= 0 ? '+' : '';
    final muted = AppColors.current.textOnCardSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'キャリブレーション（開発者）'.tr(lang),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 10),
        if (appLevel == null)
          Text(
            '参考レベルが算出できませんでした。キャリブレーションは利用できません。'.tr(lang),
            style: TextStyle(color: muted),
          )
        else ...[
          _CalibrationRow(
            label: '補正係数'.tr(lang),
            value: '$biasSign${bias.toStringAsFixed(2)}',
          ),
          _CalibrationRow(label: '評価傾向'.tr(lang), value: biasLabel.tr(lang)),
          _CalibrationRow(
            label: '学習回数'.tr(lang),
            value: '$sampleCount ${'回'.tr(lang)}',
          ),
          if (adjustedLevel != null)
            _CalibrationRow(
              label: '補正後レベル'.tr(lang),
              value:
                  'JSST ${JsstScoreCombiner.ruleBasedBandLabel(adjustedLevel)}'
                      .tr(lang),
            ),
          const SizedBox(height: 12),
          Text(
            '自己評価を入力 (JSST 1–10)'.tr(lang),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Row(
            children: [
              Text('1', style: TextStyle(color: muted)),
              Expanded(
                child: Slider(
                  value: _selectedJsstLevel.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: '$_selectedJsstLevel',
                  onChanged: (v) =>
                      setState(() => _selectedJsstLevel = v.round()),
                ),
              ),
              Text('10', style: TextStyle(color: muted)),
            ],
          ),
          Center(
            child: Text(
              'JSST $_selectedJsstLevel',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _resetCalibration,
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text('リセット'.tr(lang)),
              ),
              ElevatedButton(
                onPressed: _applyCalibration,
                child: Text('適用'.tr(lang)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CalibrationRow extends StatelessWidget {
  const _CalibrationRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final muted = AppColors.current.textOnCardSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: muted, fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
