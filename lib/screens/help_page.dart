import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../l10n/app_strings.dart';
import '../app_globals.dart';
import '../theme/app_colors.dart';
import '../theme/appearance_resolver.dart';
import '../widgets/genki_expand_card.dart';
import '../widgets/genki_subpage_scaffold.dart';
import '../widgets/swipe_down_to_dismiss.dart';
import 'privacy_page.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  String? _versionLabel;
  final _scrollController = ScrollController();

  /// 開いている節（翻訳キーの id）。
  final Set<String> _openSections = {};

  @override
  void initState() {
    super.initState();
    appSettings.addListener(_onSettingsChanged);
    _loadVersion();
  }

  @override
  void dispose() {
    appSettings.removeListener(_onSettingsChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSettingsChanged() => setState(() {});

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _versionLabel = 'バージョン %@ (%@)'.trFmt(appSettings.language, [
        info.version,
        info.buildNumber,
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = appSettings.language;
    return SwipeDownToDismiss(
      scrollController: _scrollController,
      child: GenkiSubpageScaffold(
        title: 'ヘルプ'.tr(lang),
        body: ListView(
          controller: _scrollController,
          children: [
            const SizedBox(height: 12),
            Column(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/image_icon.png',
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'osmGenki？',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.current.textOnSubpagePrimary,
                  ),
                ),
                if (_versionLabel != null)
                  Text(
                    _versionLabel!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.current.textOnSubpageSecondary,
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'ヘルプ紹介文'.tr(lang),
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppColors.current.textOnSubpagePrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final section in _visibleSections) _card(section, lang),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Material(
                color: AppColors.current.cardFill,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppColors.current.cardBorder),
                ),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  key: const ValueKey('help-privacy'),
                  leading: const Icon(
                    Icons.privacy_tip_outlined,
                    color: Colors.teal,
                  ),
                  title: Text(
                    'プライバシー'.tr(lang),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.current.textOnCardPrimary,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.current.textOnCardSecondary,
                  ),
                  onTap: () => Navigator.of(context).push(
                    fullscreenDismissRoute(
                      builder: (context) => const PrivacyPage(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// 上から 登録 → 閲覧 → 困った時 → その他 の順。色はまとまりごとに揃える。
  List<_HelpSection> get _visibleSections {
    const record = Colors.orange;
    final view = AppearanceResolver.brandBlue;
    const trouble = Colors.purple;
    const other = Colors.teal;
    return [
      const _HelpSection('talk', Icons.mic_none_rounded, record, 3),
      const _HelpSection('rally', Icons.refresh_rounded, record, 2),
      const _HelpSection('save', Icons.send_rounded, record, 3),
      if (appSettings.shakeToTalkEnabled)
        const _HelpSection('shake', Icons.vibration_rounded, record, 1),
      _HelpSection('dashboard', Icons.show_chart_rounded, view, 3),
      _HelpSection('read', Icons.menu_book_rounded, view, 3),
      _HelpSection('review', Icons.favorite_rounded, view, 3),
      const _HelpSection('copy', Icons.copy_rounded, trouble, 3),
      const _HelpSection('howto', Icons.more_horiz_rounded, trouble, 1),
      const _HelpSection('export', Icons.upload_outlined, trouble, 2),
      const _HelpSection('import', Icons.download_outlined, trouble, 3),
      // iCloud同期はiPhoneだけ（Androidでは設定にも出さない）。
      if (cloudSync != null)
        const _HelpSection('icloud', Icons.cloud_sync_rounded, other, 1),
    ];
  }

  Widget _card(_HelpSection section, String lang) {
    return Padding(
      key: ValueKey('help-section-${section.id}'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: GenkiExpandCard(
        title: 'help.${section.id}.title'.tr(lang),
        icon: section.icon,
        accent: section.accent,
        open: _openSections.contains(section.id),
        onToggle: () => setState(() {
          if (!_openSections.remove(section.id)) {
            _openSections.add(section.id);
          }
        }),
        child: GenkiStepList(
          color: section.accent,
          steps: [
            for (var i = 1; i <= section.stepCount; i++)
              'help.${section.id}.$i'.tr(lang),
          ],
        ),
      ),
    );
  }
}

/// ヘルプの 1 節。文言は `help.<id>.title` と `help.<id>.1`〜。
class _HelpSection {
  const _HelpSection(this.id, this.icon, this.accent, this.stepCount);

  final String id;
  final IconData icon;
  final Color accent;
  final int stepCount;
}
