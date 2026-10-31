import 'package:flutter/material.dart';

import '../app_globals.dart';
import '../l10n/app_strings.dart';

/// スタートアップ・使い方画面の「次回から表示しない」チェック（osm日日是好日と同じ見た目）。
class DontShowAgainCheckbox extends StatelessWidget {
  const DontShowAgainCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scene = appAppearance.sceneColor;
    final fg = appAppearance.foregroundOn(scene);
    final accent = appAppearance.accentColor;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                side: BorderSide(color: fg, width: 1.5),
                fillColor: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.selected)
                      ? accent
                      : Colors.transparent,
                ),
                checkColor: appAppearance.foregroundOn(accent),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                '次回から表示しない'.tr(appSettings.language),
                style: TextStyle(fontSize: 15, color: fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// スタートアップ・使い方画面の確定ボタン（全幅・アクセント色）。
class StartupPrimaryButton extends StatelessWidget {
  const StartupPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = appAppearance.accentColor;
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: appAppearance.foregroundOn(accent),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

/// スタートアップ・使い方画面の下部に固定する「次回から表示しない」と確定ボタン。
/// 両画面で位置がぴったり揃うよう、余白もここで決める（osm日日是好日と同じ）。
class StartupBottomBar extends StatelessWidget {
  const StartupBottomBar({
    super.key,
    required this.dontShowAgain,
    required this.onDontShowAgainChanged,
    required this.label,
    required this.onPressed,
  });

  final bool dontShowAgain;
  final ValueChanged<bool> onDontShowAgainChanged;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    // 短い画面（iPad の iPhone 互換ウィンドウなど）では上下を詰める。
    final short = MediaQuery.sizeOf(context).height <= 700;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, short ? 4 : 8, 24, short ? 12 : 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DontShowAgainCheckbox(
            value: dontShowAgain,
            onChanged: onDontShowAgainChanged,
          ),
          const SizedBox(height: 12),
          StartupPrimaryButton(label: label, onPressed: onPressed),
        ],
      ),
    );
  }
}
