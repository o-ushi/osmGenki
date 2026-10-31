import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../app_globals.dart';
import '../theme/app_colors.dart';
import '../theme/appearance_resolver.dart';
import '../widgets/genki_subpage_scaffold.dart';
import '../widgets/swipe_down_to_dismiss.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  /// Google スライド操作マニュアル（言語別・閲覧用 preview）。
  /// 共有は「リンクを知っている全員」。編集 URL ではなく preview を開く。
  /// 英語・ベトナム語は同じファイルを上書き更新する前提（ID は固定）。
  static const userManualPresentationIdJa =
      '1Ii-ernIly0Wp7y_xL9BOaA5c49KEW3rwbMZ4ABeZZNI';
  static const userManualPresentationIdEn =
      '15xtzSqvYMOoajFl_PD9RK5ZXLRx59nipnBboESVpbU4';
  static const userManualPresentationIdVi =
      '1WZZLjW7V0CXLV12VXdiqt0WtrzTQGtr1LfEAOfmLc0g';

  static String userManualUrlFor(String language) {
    final id = switch (language) {
      'en' => userManualPresentationIdEn,
      'ja' => userManualPresentationIdJa,
      _ => userManualPresentationIdVi,
    };
    return 'https://docs.google.com/presentation/d/$id/preview';
  }

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  String? _versionLabel;
  final _scrollController = ScrollController();

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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _HelpManualLink(
                languageCode: lang,
                onTap: () => launchUrl(
                  Uri.parse(HelpPage.userManualUrlFor(lang)),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ),
            _section('基本操作'.tr(lang), [
              _HelpRow(
                icon: CupertinoIcons.mic_fill,
                color: Colors.orange,
                titleKey: 'help.talk.title',
                bodyKey: 'help.talk.body',
                languageCode: lang,
              ),
              _HelpRow(
                icon: CupertinoIcons.chat_bubble_2_fill,
                color: Colors.blue,
                titleKey: 'help.rally.title',
                bodyKey: 'help.rally.body',
                languageCode: lang,
              ),
              _HelpRow(
                icon: Icons.shuffle_rounded,
                color: Colors.amber,
                titleKey: 'help.time.title',
                bodyKey: 'help.time.body',
                languageCode: lang,
              ),
              if (appSettings.shakeToTalkEnabled)
                _HelpRow(
                  icon: Icons.vibration_rounded,
                  color: Colors.teal,
                  titleKey: 'help.shake.title',
                  bodyKey: 'help.shake.body',
                  languageCode: lang,
                ),
            ]),
            _section('Chromeとのやりとり'.tr(lang), [
              _HelpRow(
                icon: Icons.mic_rounded,
                color: Colors.orange,
                titleKey: 'help.chrome.step1.title',
                bodyKey: 'help.chrome.step1.body',
                languageCode: lang,
              ),
              _HelpRow(
                icon: Icons.open_in_new_rounded,
                color: Colors.blueAccent,
                titleKey: 'help.chrome.step2.title',
                bodyKey: 'help.chrome.step2.body',
                languageCode: lang,
              ),
              _HelpRow(
                icon: Icons.copy_rounded,
                color: Colors.purple,
                titleKey: 'help.chrome.step3.title',
                bodyKey: 'help.chrome.step3.body',
                languageCode: lang,
              ),
              _HelpRow(
                icon: Icons.save_rounded,
                color: Colors.green,
                titleKey: 'help.chrome.step4.title',
                bodyKey: 'help.chrome.step4.body',
                languageCode: lang,
              ),
            ]),
            _section('振り返り'.tr(lang), [
              _HelpRow(
                icon: CupertinoIcons.chart_bar_fill,
                color: AppearanceResolver.brandBlue,
                titleKey: 'help.dashboard.title',
                bodyKey: 'help.dashboard.body',
                languageCode: lang,
              ),
              _HelpRow(
                icon: CupertinoIcons.book_fill,
                color: Colors.green,
                titleKey: 'help.diary.title',
                bodyKey: 'help.diary.body',
                languageCode: lang,
              ),
              _HelpRow(
                icon: Icons.favorite_rounded,
                color: Colors.pink,
                titleKey: 'help.review.title',
                bodyKey: 'help.review.body',
                languageCode: lang,
              ),
            ]),
            _section('データ'.tr(lang), [
              _HelpRow(
                icon: Icons.import_export_rounded,
                color: Colors.indigo,
                titleKey: 'help.backup.title',
                bodyKey: 'help.backup.body',
                languageCode: lang,
              ),
              // iCloud同期はiPhoneだけ（Androidでは設定にも出さない）。
              if (cloudSync != null)
                _HelpRow(
                  icon: Icons.cloud_sync_rounded,
                  color: Colors.lightBlue,
                  titleKey: 'help.icloud.title',
                  bodyKey: 'help.icloud.body',
                  languageCode: lang,
                ),
            ]),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.current.textOnSubpageSecondary,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _HelpManualLink extends StatelessWidget {
  const _HelpManualLink({required this.languageCode, required this.onTap});

  final String languageCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.current;
    final accent = palette.scene;
    return Material(
      color: palette.cardFill,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        key: const Key('help_user_manual'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.cardBorder),
          ),
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.menu_book_outlined,
                  color: palette.textOnScenePrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '操作マニュアル'.tr(languageCode),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: palette.textOnCardPrimary,
                      ),
                    ),
                    Text(
                      '図解で画面ごとの使い方を見る'.tr(languageCode),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: palette.textOnCardSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpRow extends StatelessWidget {
  const _HelpRow({
    required this.icon,
    required this.color,
    required this.titleKey,
    required this.bodyKey,
    required this.languageCode,
  });

  final IconData icon;
  final Color color;
  final String titleKey;
  final String bodyKey;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titleKey.tr(languageCode),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _HelpBodyText(text: bodyKey.tr(languageCode)),
        ],
      ),
    );
  }
}

/// ヘルプ本文の描画。「%ICON%」を含む場合は、そこをコピーボタンのアイコンに
/// 差し替えて、実際にタップしてほしいボタンの絵と一緒に説明する
/// （osmWashabeの「お題の取り込み」画面のコピーボタン表記を踏襲）。
class _HelpBodyText extends StatelessWidget {
  const _HelpBodyText({required this.text});

  static const _iconMarker = '%ICON%';

  final String text;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: AppColors.current.textOnSubpageSecondary,
      height: 1.4,
    );

    if (!text.contains(_iconMarker)) {
      return Text(text, style: style);
    }

    final parts = text.split(_iconMarker);
    return Text.rich(
      TextSpan(
        children: [
          for (var i = 0; i < parts.length; i++) ...[
            TextSpan(text: parts[i]),
            if (i != parts.length - 1)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: AppColors.current.textOnSubpageSecondary,
                ),
              ),
          ],
        ],
      ),
      // Text(text, style: style)と同じ経路でスタイルを解決させ、他の項目と
      // フォントの太さ・色が揃うようにする（TextSpan側にだけstyleを置くと、
      // Text.rich自身のDefaultTextStyleマージ経路を通らず太さがずれていた）。
      style: style,
    );
  }
}
