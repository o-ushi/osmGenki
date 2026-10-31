import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../widgets/google_ai_consent_dialog.dart';
import 'google_ai_link.dart';

/// Chrome AIモードへの往復（同意確認→クリップボード→URL起動）の共通処理。
abstract final class ChromeAiRoundTrip {
  /// 同意確認のうえ、[prompt]をコピーしてChrome AIモードを開く。
  /// 同意されなければ false。起動に失敗した場合も false（SnackBar を出す）。
  /// 同意後に起動まで完了すれば true。
  static Future<bool> ensureConsentAndOpen({
    required BuildContext context,
    required String prompt,
    required String lang,
    required String titleKey,
    required String bodyKey,
    required Future<void> Function() onAcquireKeepAlive,
  }) async {
    final consented = await confirmSendToGoogleAi(
      context,
      lang: lang,
      titleKey: titleKey,
      bodyKey: bodyKey,
    );
    if (!consented) return false;

    await Clipboard.setData(ClipboardData(text: prompt));
    // 初回起動が数百ms かかりうるため待たない。
    unawaited(onAcquireKeepAlive());

    var opened = false;
    try {
      opened = await GoogleAiLink.openWithPrompt(prompt, lang: lang);
    } catch (e, st) {
      debugPrint('osmGenki: Chrome AI open failed: $e\n$st');
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chromeを開けなかった'.tr(lang))),
      );
    }
    return opened;
  }

  /// クリップボードのプレーンテキストを返す（未設定・空は null）。
  static Future<String?> readClipboardText() async {
    final clipboard = await Clipboard.getData('text/plain');
    final text = clipboard?.text?.trim() ?? '';
    if (text.isEmpty) return null;
    return text;
  }

  /// Chromeへ送る直前にコピーした[sentPrompt]が、まだクリップボードに
  /// 残っているかどうか。AI回答をコピーせずアプリに戻ったときの誤保存
  /// （アプリ復帰時の自動貼り付けが、送信済みプロンプトをそのまま結果として
  /// 保存してしまう事故）を防ぐために使う。
  static bool isUnchangedSentPrompt(String? clipboard, String sentPrompt) {
    if (clipboard == null) return false;
    return clipboard.trim() == sentPrompt.trim();
  }
}
