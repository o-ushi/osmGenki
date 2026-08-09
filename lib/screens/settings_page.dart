import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../app_globals.dart';
import '../services/diary_backup_actions.dart';
import '../services/jsst_calibration_service.dart';
import '../theme/app_colors.dart';
import '../services/timer_completion_sound_catalog.dart';
import '../widgets/genki_subpage_scaffold.dart';
import '../widgets/language_picker.dart';
import '../widgets/swipe_down_to_dismiss.dart';
import 'privacy_page.dart';
import 'speech_recognition_debug_log_page.dart';
import 'timer_sound_picker_page.dart';

/// osmWashabeの設定画面フォーマット（並び順・言語タイル・カード/区切り線）を踏襲。
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _scrollController = ScrollController();
  int _devTapCount = 0;

  @override
  void initState() {
    super.initState();
    appSettings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    appSettings.removeListener(_onSettingsChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onSettingsChanged() => setState(() {});

  void _onDevAreaTap() {
    setState(() {
      _devTapCount++;
      if (_devTapCount >= 7) {
        appSettings.developerModeEnabled = !appSettings.developerModeEnabled;
        _devTapCount = 0;
        final lang = appSettings.language;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              appSettings.developerModeEnabled
                  ? '開発者モードを有効にしました'.tr(lang)
                  : '開発者モードを無効にしました'.tr(lang),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = appSettings.language;
    return SwipeDownToDismiss(
      scrollController: _scrollController,
      child: GenkiSubpageScaffold(
        title: '設定'.tr(lang),
        body: ListView(
          controller: _scrollController,
          children: [
            const SizedBox(height: 12),
            _sectionHeader('言語'.tr(lang)),
            _card(const [LanguagePickerList()]),
            _noteText('アプリの表示言語を変更できます。'.tr(lang)),

            _sectionHeader('週の開始'.tr(lang)),
            _card([
              _ChoiceTile(
                label: '日曜始まり'.tr(lang),
                selected: !appSettings.weekStartsMonday,
                onTap: () => appSettings.weekStartsMonday = false,
              ),
              const _ItemDivider(),
              _ChoiceTile(
                label: '月曜始まり'.tr(lang),
                selected: appSettings.weekStartsMonday,
                onTap: () => appSettings.weekStartsMonday = true,
              ),
            ]),
            _noteText('カレンダーの週の始まりを選べます。'.tr(lang)),

            _sectionHeader('タイマー設定'.tr(lang)),
            _card([
              _NavigationTile(
                label: 'タイマー音'.tr(lang),
                value: TimerCompletionSoundCatalog.displayName(
                  appSettings.completionSound,
                  lang,
                ),
                onTap: () => Navigator.of(context).push(
                  fullscreenDismissRoute(
                    builder: (context) =>
                        TimerSoundPickerPage(languageCode: lang),
                  ),
                ),
              ),
            ]),

            _sectionHeader('スタートアップ画面'.tr(lang)),
            _card([
              _SwitchTile(
                label: 'スタートアップ画面'.tr(lang),
                subtitle: 'スタートアップ画面_説明'.tr(lang),
                value: appSettings.showStartupScreen,
                onChanged: (value) => appSettings.showStartupScreen = value,
              ),
            ]),

            _sectionHeader('操作'.tr(lang)),
            _card([
              _SwitchTile(
                label: 'シェイクで話す'.tr(lang),
                subtitle: 'シェイクで話す_説明'.tr(lang),
                value: appSettings.shakeToTalkEnabled,
                onChanged: (value) => appSettings.shakeToTalkEnabled = value,
              ),
            ]),

            _sectionHeader('データ'.tr(lang)),
            _card([
              _NavigationTile(
                label: '日記をエクスポート'.tr(lang),
                onTap: () => exportDiary(context),
              ),
              const _ItemDivider(),
              _NavigationTile(
                label: '日記をインポート'.tr(lang),
                onTap: () => importDiary(context),
              ),
            ]),

            _sectionHeader('プライバシー'.tr(lang)),
            _card([
              _NavigationTile(
                label: 'プライバシー'.tr(lang),
                onTap: () => Navigator.of(context).push(
                  fullscreenDismissRoute(
                    builder: (context) => const PrivacyPage(),
                  ),
                ),
              ),
            ]),

            if (appSettings.developerModeEnabled) ...[
              _sectionHeader('開発者向け'.tr(lang)),
              _card([
                _calibrationBiasTile(lang),
                const _ItemDivider(),
                _NavigationTile(
                  label: '音声認識ログ'.tr(lang),
                  onTap: () => Navigator.of(context).push(
                    fullscreenDismissRoute(
                      builder: (context) =>
                          SpeechRecognitionDebugLogPage(languageCode: lang),
                    ),
                  ),
                ),
              ]),
              _noteText('音声認識ログ_設定説明'.tr(lang)),
            ],
            // osmWashabeと同じ、見えない開発者モード切り替え領域。
            GestureDetector(
              onTap: _onDevAreaTap,
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(height: 40, width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.current.textOnSubpageSecondary,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.current.cardFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: children),
    );
  }

  Widget _noteText(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.current.textOnSubpageSecondary,
          fontSize: 13,
        ),
      ),
    );
  }

  /// osmWashabeと同じ、JSST採点キャリブレーション（開発者モード専用）の補正係数の
  /// 確認欄。値そのものは「スコアの内訳」ダイアログの[CalibrationSection]で更新する。
  Widget _calibrationBiasTile(String lang) {
    final bias = appSettings.calibrationBias;
    final count = appSettings.calibrationSampleCount;
    final sign = bias >= 0 ? '+' : '';
    final tendency = JsstCalibrationService.biasLabel(bias).tr(lang);
    final value = count == 0
        ? '—'
        : '$sign${bias.toStringAsFixed(2)}（$tendency）';
    return _ValueTile(label: '補正係数'.tr(lang), value: value);
  }
}

/// ラベル＋値のみの行（[_NavigationTile]と違いタップでの遷移がなく、矢印も出さない）。
class _ValueTile extends StatelessWidget {
  const _ValueTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 17,
                color: AppColors.current.textOnCardPrimary,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              softWrap: true,
              style: TextStyle(
                color: AppColors.current.textOnCardSecondary,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemDivider extends StatelessWidget {
  const _ItemDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 0.5,
      indent: 16,
      color: AppColors.current.cardBorder,
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  color: AppColors.current.textOnCardPrimary,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check, color: AppColors.current.accentColor, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 17,
                      color: AppColors.current.textOnCardPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.current.textOnCardSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(
              value: value,
              activeThumbColor: AppColors.current.onAccent,
              activeTrackColor: AppColors.current.accentColor,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  const _NavigationTile({required this.label, required this.onTap, this.value});

  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  color: AppColors.current.textOnCardPrimary,
                ),
              ),
            ),
            if (value != null)
              Flexible(
                child: Text(
                  value!,
                  textAlign: TextAlign.end,
                  softWrap: true,
                  style: TextStyle(
                    color: AppColors.current.textOnCardSecondary,
                    fontSize: 17,
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right,
              color: AppColors.current.textOnCardSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
