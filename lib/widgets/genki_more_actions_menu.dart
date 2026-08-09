import 'package:flutter/material.dart';

import '../app_globals.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';

/// osmWashabeの `WashabeMoreActionsMenu` に相当。設定・ヘルプに加えて、
/// osmSolverのホーム画面オーバーフローメニューと同じくエクスポート・インポートも並べる。
class GenkiMoreActionsMenu extends StatelessWidget {
  const GenkiMoreActionsMenu({
    super.key,
    required this.languageCode,
    required this.onExport,
    required this.onImport,
    required this.onSettings,
    required this.onHelp,
  });

  final String languageCode;
  final VoidCallback onExport;
  final VoidCallback onImport;
  final VoidCallback onSettings;
  final VoidCallback onHelp;

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.current.cardFill;
    final iconFg = appAppearance.foregroundOn(surface);
    final iconBg = appAppearance.subtleFill(surface, 0.12);
    final iconBorder = appAppearance.mutedOn(surface);

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(12),
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _menuButton(
              icon: Icons.upload_outlined,
              label: '日記をエクスポート'.tr(languageCode),
              iconFg: iconFg,
              iconBg: iconBg,
              iconBorder: iconBorder,
              onTap: onExport,
            ),
            const SizedBox(width: 16),
            _menuButton(
              icon: Icons.download_outlined,
              label: '日記をインポート'.tr(languageCode),
              iconFg: iconFg,
              iconBg: iconBg,
              iconBorder: iconBorder,
              onTap: onImport,
            ),
            const SizedBox(width: 16),
            _menuButton(
              icon: Icons.settings_outlined,
              label: '設定'.tr(languageCode),
              iconFg: iconFg,
              iconBg: iconBg,
              iconBorder: iconBorder,
              onTap: onSettings,
            ),
            const SizedBox(width: 16),
            _menuButton(
              icon: Icons.help_outline_rounded,
              label: 'ヘルプ'.tr(languageCode),
              iconFg: iconFg,
              iconBg: iconBg,
              iconBorder: iconBorder,
              onTap: onHelp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuButton({
    required IconData icon,
    required String label,
    required Color iconFg,
    required Color iconBg,
    required Color iconBorder,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: iconBorder, width: 1.5),
          ),
          child: Icon(icon, color: iconFg, size: 26),
        ),
      ),
    );
  }
}
