import 'package:flutter/material.dart';

import '../app_globals.dart';

/// osmWashabeの `_SessionBar` に相当する、常時表示のタブ切り替えツールバー。
class GenkiToolbar extends StatelessWidget {
  const GenkiToolbar({
    super.key,
    required this.moreButtonKey,
    required this.scene,
    required this.foreground,
    required this.talkSelected,
    required this.dashboardSelected,
    required this.diarySelected,
    required this.talkTooltip,
    required this.dashboardTooltip,
    required this.diaryTooltip,
    required this.moreTooltip,
    required this.onTalk,
    required this.onDashboard,
    required this.onDiary,
    required this.onMore,
    this.onMoreLongPress,
  });

  final GlobalKey moreButtonKey;
  final Color scene;
  final Color foreground;
  final bool talkSelected;
  final bool dashboardSelected;
  final bool diarySelected;
  final String talkTooltip;
  final String dashboardTooltip;
  final String diaryTooltip;
  final String moreTooltip;
  final VoidCallback onTalk;
  final VoidCallback onDashboard;
  final VoidCallback onDiary;
  final VoidCallback onMore;

  /// 非nullの場合、[•••]の長押しで呼ぶ（現在のタブに応じた使い方シートを開く導線）。
  final VoidCallback? onMoreLongPress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ToolbarIconButton(
            icon: Icons.mic_none_rounded,
            tooltip: talkTooltip,
            selected: talkSelected,
            scene: scene,
            foreground: foreground,
            onTap: onTalk,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ToolbarIconButton(
            icon: Icons.insights_rounded,
            tooltip: dashboardTooltip,
            selected: dashboardSelected,
            scene: scene,
            foreground: foreground,
            onTap: onDashboard,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ToolbarIconButton(
            icon: Icons.menu_book_rounded,
            tooltip: diaryTooltip,
            selected: diarySelected,
            scene: scene,
            foreground: foreground,
            onTap: onDiary,
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: moreTooltip,
          child: Material(
            key: moreButtonKey,
            color: appAppearance.subtleFill(scene, 0.08),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onMore,
              onLongPress: onMoreLongPress,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Icon(Icons.more_horiz, color: foreground, size: 24),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToolbarIconButton extends StatelessWidget {
  const _ToolbarIconButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.scene,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final Color scene;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected
        ? appAppearance.foregroundOn(appAppearance.accentColor)
        : foreground;
    final iconWidget = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Icon(icon, color: iconColor, size: 24),
    );

    return Semantics(
      button: true,
      label: tooltip,
      selected: selected,
      child: Tooltip(
        message: tooltip,
        child: Material(
          clipBehavior: Clip.none,
          color: selected
              ? appAppearance.accentColor
              : appAppearance.subtleFill(scene, 0.08),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: SizedBox(
              width: double.infinity,
              child: Center(child: iconWidget),
            ),
          ),
        ),
      ),
    );
  }
}
