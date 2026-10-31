import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../app_globals.dart';
import '../widgets/language_flag_button.dart';
import '../widgets/startup_bottom_bar.dart';

/// インストール直後（および設定で有効なとき）に出す案内画面。
/// 右上の国旗ボタンで表示言語を切り替えられる。
/// 「次回から表示しない」と「はじめる」は osm日日是好日と同じく画面下に固定する。
class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key, required this.onContinue});

  /// [dontShowAgain]がtrueなら、呼び出し側で次回表示オフを保存する。
  final ValueChanged<bool> onContinue;

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // 濃いシーン色の上ではステータスバーの文字を白にする。
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: Image.asset(
                                  'assets/images/app_icon.png',
                                  width: 140,
                                  height: 140,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'osmGenki？',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                softWrap: false,
                                textScaler: TextScaler.noScaling,
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: fg,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'スタートアップ_説明'.tr(lang),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.45,
                                color: muted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text.rich(
                              TextSpan(
                                style: TextStyle(fontSize: 12, color: muted),
                                children: [
                                  TextSpan(text: '起動_操作ヒント_前'.tr(lang)),
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.middle,
                                    child: Icon(
                                      Icons.more_horiz,
                                      size: 14,
                                      color: muted,
                                    ),
                                  ),
                                  TextSpan(text: '起動_操作ヒント_後'.tr(lang)),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // 説明を読まなくても始められるよう、osm日日是好日と同じく下部に固定する。
              StartupBottomBar(
                dontShowAgain: _dontShowAgain,
                onDontShowAgainChanged: (v) =>
                    setState(() => _dontShowAgain = v),
                label: 'はじめる'.tr(lang),
                onPressed: () => widget.onContinue(_dontShowAgain),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
