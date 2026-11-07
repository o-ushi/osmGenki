import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../app_globals.dart';
import '../services/cloud_sync/cloud_sync_service.dart';
import '../services/diary_backup_actions.dart';
import '../services/jsst_calibration_service.dart';
import '../theme/app_colors.dart';
import '../services/timer_completion_sound_catalog.dart';
import '../widgets/genki_expand_card.dart';
import '../widgets/genki_subpage_scaffold.dart';
import '../widgets/language_picker.dart';
import '../widgets/swipe_down_to_dismiss.dart';
import 'speech_recognition_debug_log_page.dart';
import 'timer_sound_picker_page.dart';

/// 表示言語の下に、開閉するグループを並べる。
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _scrollController = ScrollController();
  int _devTapCount = 0;

  /// 開いているグループ（見出しの翻訳キー）。
  final Set<String> _open = {};

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
            _card([LanguagePickerList()]),
            _noteText('アプリの表示言語を変更できます。'.tr(lang)),

            const SizedBox(height: 20),
            _group('ふだんの使い方', Icons.tune_rounded, Colors.orange, [
              _groupLabel('週の開始'.tr(lang)),
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
              _noteOnCard('カレンダーの週の始まりを選べます。'.tr(lang)),
              const _ItemDivider(),
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
              const _ItemDivider(),
              _SwitchTile(
                label: 'シェイクで話す'.tr(lang),
                subtitle: 'シェイクで話す_説明'.tr(lang),
                value: appSettings.shakeToTalkEnabled,
                onChanged: (value) => appSettings.shakeToTalkEnabled = value,
              ),
              const _ItemDivider(),
              _SwitchTile(
                label: 'スタートアップ画面'.tr(lang),
                subtitle: 'スタートアップ画面_説明'.tr(lang),
                value: appSettings.showStartupScreen,
                onChanged: (value) => appSettings.showStartupScreen = value,
              ),
              const _ItemDivider(),
              // 使い方はスタートアップがONのときだけ切り替えられる（osm日日是好日と同じ）。
              _SwitchTile(
                label: '使い方画面'.tr(lang),
                subtitle: '使い方画面_説明'.tr(lang),
                value: appSettings.showUsageScreen,
                onChanged: appSettings.showStartupScreen
                    ? (value) => appSettings.showUsageScreen = value
                    : null,
              ),
            ]),
            _group('データ', Icons.storage_rounded, Colors.indigo, [
              _NavigationTile(
                label: '日記をエクスポート'.tr(lang),
                onTap: () => exportDiary(context),
              ),
              const _ItemDivider(),
              _NavigationTile(
                label: '日記をインポート'.tr(lang),
                onTap: () => importDiary(context),
              ),
              // iCloud同期（iPhoneのみ。Androidでは出さない）。
              if (cloudSync case final sync?) ...[
                const _ItemDivider(),
                _CloudSyncCard(
                  sync: sync,
                  card: (children) => Column(children: children),
                  noteText: _noteOnCard,
                ),
              ],
            ]),
            if (appSettings.developerModeEnabled)
              _group('開発者向け', Icons.code_rounded, Colors.grey, [
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
                _noteOnCard('音声認識ログ_設定説明'.tr(lang)),
              ]),
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

  Widget _group(
    String titleKey,
    IconData icon,
    Color accent,
    List<Widget> children,
  ) {
    return Padding(
      key: ValueKey('settings-group-$titleKey'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: GenkiExpandCard(
        title: titleKey.tr(appSettings.language),
        icon: icon,
        accent: accent,
        open: _open.contains(titleKey),
        onToggle: () => setState(() {
          if (!_open.remove(titleKey)) _open.add(titleKey);
        }),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [...children, const SizedBox(height: 8)],
        ),
      ),
    );
  }

  /// カードの中の小さな見出し。
  Widget _groupLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 2),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.current.textOnCardSecondary,
          fontSize: 13,
        ),
      ),
    );
  }

  /// カードの中の注記。
  Widget _noteOnCard(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.current.textOnCardSecondary,
          fontSize: 13,
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

/// iCloud同期（osmGradusの設定と同じ要素: オン／オフ・未サインインの注意・
/// 最終同期・今すぐ同期・エラー）。
class _CloudSyncCard extends StatelessWidget {
  const _CloudSyncCard({
    required this.sync,
    required this.card,
    required this.noteText,
  });

  final CloudSyncService sync;
  final Widget Function(List<Widget> children) card;
  final Widget Function(String text) noteText;

  /// 「今すぐ同期」。終わったら結果をスナックバーで知らせる
  /// （送るものが無くても反応が分かるように）。
  Future<void> _syncNow(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await sync.manualSync();
    final lang = appSettings.language;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text((ok ? 'iCloud同期_完了' : 'iCloud同期_失敗_短').tr(lang)),
        ),
      );
  }

  String _formatLast(DateTime last, String lang) {
    final hh = last.hour.toString().padLeft(2, '0');
    final mm = last.minute.toString().padLeft(2, '0');
    return '${AppStrings.dateLabel(last, lang)} $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sync,
      builder: (context, _) {
        final lang = appSettings.language;
        final enabled = sync.isEnabled;
        final unavailable =
            sync.status == CloudSyncStatus.unavailable ||
            sync.icloudAvailable == false;
        final last = sync.lastSyncDate;
        final errorText = switch (sync.error) {
          CloudSyncError.tooLarge => 'iCloud同期_容量超過'.trFmt(lang, [
            ((sync.errorBytes ?? 0) / 1000000).toStringAsFixed(1),
          ]),
          CloudSyncError.failed => 'iCloud同期_失敗'.tr(lang),
          null => null,
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            card([
              _SwitchTile(
                key: const ValueKey('settings-cloud-sync'),
                label: 'iCloudで同期する'.tr(lang),
                subtitle: 'iCloud同期_スイッチ説明'.tr(lang),
                value: enabled,
                onChanged: (value) => sync.setEnabled(value),
              ),
              if (enabled && !unavailable) ...[
                const _ItemDivider(),
                _ValueTile(
                  label: last == null
                      ? 'iCloud同期_未同期'.tr(lang)
                      : 'iCloud同期_最終同期'.tr(lang),
                  value: last == null ? '' : _formatLast(last, lang),
                ),
                const _ItemDivider(),
                Opacity(
                  opacity: sync.isWorking ? 0.4 : 1,
                  child: _NavigationTile(
                    key: const ValueKey('settings-cloud-sync-now'),
                    label: sync.isWorking
                        ? 'iCloud同期_同期中'.tr(lang)
                        : 'iCloud同期_今すぐ同期'.tr(lang),
                    onTap: sync.isWorking ? () {} : () => _syncNow(context),
                  ),
                ),
              ],
            ]),
            if (enabled && unavailable)
              _CloudSyncWarning('iCloud同期_未サインイン'.tr(lang)),
            if (enabled && errorText != null) _CloudSyncWarning(errorText),
            noteText('iCloud同期_説明'.tr(lang)),
          ],
        );
      },
    );
  }
}

class _CloudSyncWarning extends StatelessWidget {
  const _CloudSyncWarning(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Text(
        text,
        style: const TextStyle(color: Colors.red, fontSize: 13),
      ),
    );
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
    super.key,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String subtitle;
  final bool value;

  /// null なら無効表示（タップもスイッチも効かない）。
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final onChanged = this.onChanged;
    final enabled = onChanged != null;
    return InkWell(
      onTap: enabled ? () => onChanged(!value) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Opacity(
                opacity: enabled ? 1 : 0.4,
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
  const _NavigationTile({
    super.key,
    required this.label,
    required this.onTap,
    this.value,
  });

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
