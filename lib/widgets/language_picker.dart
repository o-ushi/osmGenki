import 'package:flutter/material.dart';

import '../app_globals.dart';
import '../data/app_languages.dart';
import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';

/// [appLanguages] から言語選択行を並べる共通リスト。
/// 設定画面のカード内と、国旗ボタンのボトムシートの両方で使う。
class LanguagePickerList extends StatelessWidget {
  const LanguagePickerList({
    super.key,
    this.compact = false,
    this.popOnSelect = false,
  });

  /// true ならボトムシート向けのやや詰めた余白・フォントにする。
  final bool compact;

  /// true なら選択後に [Navigator.pop] する（シート向け）。
  final bool popOnSelect;

  @override
  Widget build(BuildContext context) {
    final lang = appSettings.language;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < appLanguages.length; i++) ...[
          if (i > 0 && !compact)
            Divider(
              height: 1,
              thickness: 0.5,
              indent: 16,
              color: AppColors.current.cardBorder,
            ),
          _LanguageOptionRow(
            code: appLanguages[i].$1,
            name: appLanguages[i].$2,
            flag: appLanguages[i].$3,
            selected: lang == appLanguages[i].$1,
            compact: compact,
            popOnSelect: popOnSelect,
          ),
        ],
      ],
    );
  }
}

/// 国旗ボタンなどから開く言語選択ボトムシート。
Future<void> showLanguagePickerSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.current.cardFill,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const LanguagePickerSheet(),
  );
}

class LanguagePickerSheet extends StatelessWidget {
  const LanguagePickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = appSettings.language;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.current.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '言語'.tr(lang),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.current.textOnCardPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const LanguagePickerList(compact: true, popOnSelect: true),
          ],
        ),
      ),
    );
  }
}

class _LanguageOptionRow extends StatelessWidget {
  const _LanguageOptionRow({
    required this.code,
    required this.name,
    required this.flag,
    required this.selected,
    required this.compact,
    required this.popOnSelect,
  });

  final String code;
  final String name;
  final String flag;
  final bool selected;
  final bool compact;
  final bool popOnSelect;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        appSettings.language = code;
        if (popOnSelect) Navigator.of(context).pop();
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 0 : 16,
          vertical: compact ? 12 : 12,
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: compact ? 16 : 17,
                  color: compact
                      ? AppColors.current.textOnCardPrimary.withValues(
                          alpha: 0.87,
                        )
                      : AppColors.current.textOnCardPrimary,
                ),
              ),
            ),
            if (selected)
              Icon(
                Icons.check,
                color: AppColors.current.accentColor,
                size: compact ? 24 : 20,
              ),
          ],
        ),
      ),
    );
  }
}
