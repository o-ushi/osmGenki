import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../app_globals.dart';
import '../services/privacy_consent.dart';
import '../theme/app_colors.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/factory_reset_action.dart';
import '../widgets/genki_subpage_scaffold.dart';
import '../widgets/swipe_down_to_dismiss.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  static final _applePrivacy = Uri.parse(
    'https://www.apple.com/legal/privacy/',
  );
  static final _googlePrivacy = Uri.parse(
    'https://policies.google.com/privacy',
  );
  static final _appPrivacyPolicy = Uri.parse(
    'https://docs.google.com/document/d/1vUD5NWUC8ta0j-VAl4UkXCy-nA4zIRiTdDgkR-9jcyo/edit?usp=sharing',
  );

  final _scrollController = ScrollController();

  /// iOS/Androidで実装が異なる（iOSはApple Speech Recognitionのみ、
  /// AndroidはOSの音声認識→失敗時Voskフォールバック）ため、文言も
  /// プラットフォームごとに分ける。それ以外（未対応OS等）は既存の汎用文言。
  String get _speechRecognitionExplanationKey {
    if (Platform.isIOS) return 'Privacy_音声認識説明_iOS';
    if (Platform.isAndroid) return 'Privacy_音声認識説明_Android';
    return '音声認識同意_本文';
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _revokeSpeechConsent() async {
    final lang = appSettings.language;
    final confirmed = await showConfirmDialog(
      context,
      title: '音声認識同意_撤回確認タイトル'.tr(lang),
      message: '音声認識同意_撤回確認本文'.tr(lang),
      confirmLabel: '撤回する'.tr(lang),
      cancelLabel: 'キャンセル'.tr(lang),
    );
    if (!confirmed) return;
    await PrivacyConsent.revokeSpeechConsent(appSettings.prefs);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lang = appSettings.language;
    final consented = PrivacyConsent.hasCurrentSpeechConsent(appSettings.prefs);
    return SwipeDownToDismiss(
      scrollController: _scrollController,
      child: GenkiSubpageScaffold(
        title: 'プライバシー'.tr(lang),
        body: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _section(
              'OS音声認識'.tr(lang),
              _speechRecognitionExplanationKey.tr(lang),
              icon: Icons.mic_none,
              trailing: _consentBadge(consented: consented, lang: lang),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Privacy_設定への案内'.tr(lang),
                style: TextStyle(
                  color: AppColors.current.textOnSubpageSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
            if (consented)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: OutlinedButton(
                    onPressed: _revokeSpeechConsent,
                    child: Text('同意を撤回'.tr(lang)),
                  ),
                ),
              ),
            _section(
              'Google AI'.tr(lang),
              'Privacy_Google説明'.tr(lang),
              icon: Icons.travel_explore,
            ),
            _section(
              '保存・削除・バックアップ'.tr(lang),
              'Privacy_保存削除説明'.tr(lang),
              icon: Icons.folder_open,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('本アプリのプライバシーポリシー'.tr(lang)),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => launchUrl(
                _appPrivacyPolicy,
                mode: LaunchMode.externalApplication,
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Appleプライバシーポリシー'.tr(lang)),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => launchUrl(
                _applePrivacy,
                mode: LaunchMode.externalApplication,
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Googleプライバシーポリシー'.tr(lang)),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => launchUrl(
                _googlePrivacy,
                mode: LaunchMode.externalApplication,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: kRecordingColor.withValues(alpha: 0.08),
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(
                  Icons.delete_forever,
                  color: kRecordingColor,
                ),
                title: Text(
                  '初期化'.tr(lang),
                  style: const TextStyle(
                    color: kRecordingColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text('初期化_説明'.tr(lang)),
                onTap: () async {
                  await confirmFactoryReset(context);
                  if (mounted) setState(() {});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _consentBadge({required bool consented, required String lang}) {
    final color = consented ? kPasteReadyColor : kRecordingColor;
    final label = consented ? '同意中' : '未同意';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          consented ? Icons.verified_user : Icons.error_outline,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label.tr(lang),
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _section(
    String title,
    String body, {
    IconData? icon,
    Widget? trailing,
  }) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: AppColors.current.textOnCardSecondary),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 8),
          Text(body),
        ],
      ),
    ),
  );
}
