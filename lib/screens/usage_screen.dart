import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_globals.dart';
import '../l10n/app_strings.dart';
import '../widgets/language_flag_button.dart';
import '../widgets/startup_bottom_bar.dart';
import '../widgets/swipe_to_close_wrapper.dart';

/// スタートアップの「はじめる」の後（設定で有効なとき）に出す、
/// AI診断（Chrome の AI モード）の使い方の画面。構成は osm日日是好日の UsageScreen と同じ。
/// 「次回から表示しない」と確定ボタンは画面下に固定する。
///
/// ボタンでの確定に加え、左端からの右スワイプでも（チェックを保存せず）
/// スタートアップへ戻れる（[onSwipeToStartup]）。
class UsageScreen extends StatefulWidget {
  const UsageScreen({
    super.key,
    required this.onContinue,
    this.onSwipeToStartup,
  });

  /// [dontShowAgain] が true なら、呼び出し側で次回表示オフを保存する。
  final ValueChanged<bool> onContinue;

  /// 左端からの右スワイプでスタートアップへ戻る操作。未指定ならスワイプは付けない。
  final VoidCallback? onSwipeToStartup;

  @override
  State<UsageScreen> createState() => _UsageScreenState();
}

class _UsageScreenState extends State<UsageScreen> {
  bool _dontShowAgain = false;

  @override
  void initState() {
    super.initState();
    appSettings.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    appSettings.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final lang = appSettings.language;
    final scene = appAppearance.sceneColor;
    final fg = appAppearance.foregroundOn(scene);
    final muted = appAppearance.mutedOn(scene);
    final body = TextStyle(fontSize: 15, height: 1.5, color: muted);

    final scaffold = AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: scene,
        body: SafeArea(
          child: Column(
            children: [
              const Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0, 4, 12, 0),
                  child: LanguageFlagButton(),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '使い方'.tr(lang),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: fg,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // 本文が「下の画像の…」と画像を指すので、本文 → 画像の順にする。
                      Text(
                        '使い方_Chrome見出し'.tr(lang),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('使い方_コピー本文'.tr(lang), style: body),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ColoredBox(
                          color: Colors.white,
                          child: Image.asset(
                            'assets/images/chrome_ai_copy_button.png',
                            width: double.infinity,
                            fit: BoxFit.contain,
                            semanticLabel: '使い方_コピー画像ラベル'.tr(lang),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // スタートアップと同じく、読み終えなくても進めるよう下部に固定する。
              StartupBottomBar(
                dontShowAgain: _dontShowAgain,
                onDontShowAgainChanged: (v) =>
                    setState(() => _dontShowAgain = v),
                label: 'ホーム画面へ'.tr(lang),
                onPressed: () => widget.onContinue(_dontShowAgain),
              ),
            ],
          ),
        ),
      ),
    );

    final onSwipeToStartup = widget.onSwipeToStartup;
    if (onSwipeToStartup == null) return scaffold;
    return SwipeToCloseWrapper(onClose: onSwipeToStartup, child: scaffold);
  }
}
