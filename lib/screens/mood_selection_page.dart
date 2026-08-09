import 'package:flutter/material.dart';

import '../app_globals.dart';
import '../l10n/app_strings.dart';
import '../models/mood_level.dart';
import '../widgets/swipe_to_close_wrapper.dart';
import 'home_page.dart';

/// アプリ起動直後に表示する、5段階の気分（元気度）選択画面。
///
/// タップされた気分は遷移先の「録音・入力画面」（[HomePage]）へ引数として渡される。
class MoodSelectionPage extends StatefulWidget {
  const MoodSelectionPage({super.key, this.onShowStartup});

  /// 左端からの右スワイプで[StartupScreen]へ戻る操作を呼ぶ。
  /// 設定の「スタートアップ画面」がONかつこれが指定されているときだけ
  /// [SwipeToCloseWrapper]を有効にする（OFFなら不要なため何もしない）。
  final VoidCallback? onShowStartup;

  @override
  State<MoodSelectionPage> createState() => _MoodSelectionPageState();
}

class _MoodSelectionPageState extends State<MoodSelectionPage> {
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

  void _onMoodSelected(BuildContext context, MoodLevel mood) {
    _goToRecordingScreen(context, mood);
  }

  void _goToRecordingScreen(BuildContext context, MoodLevel mood) {
    // pushReplacementではなくpushにして、録音・入力画面側から気分選択画面へ
    // 戻れるようにスタックに残しておく。
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => HomePage(moodLevel: mood)));
  }

  @override
  Widget build(BuildContext context) {
    final scene = appAppearance.sceneColor;
    final fg = appAppearance.foregroundOn(scene);
    final moods = MoodLevel.values.toList().reversed.toList();
    final lang = appSettings.language;

    final scaffold = Scaffold(
      backgroundColor: scene,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      // 日本語会話力向上アプリとしての「問いかけ」なので、表示言語に
                      // 関わらず常に日本語で表示する。
                      '元気してる？'.trJa,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: fg,
                        fontSize: 52,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  children: [
                    for (var i = 0; i < moods.length; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      Expanded(
                        child: _MoodFaceButton(
                          mood: moods[i],
                          scene: scene,
                          foreground: fg,
                          lang: lang,
                          onTap: () => _onMoodSelected(context, moods[i]),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final onShowStartup = widget.onShowStartup;
    if (!appSettings.showStartupScreen || onShowStartup == null) {
      return scaffold;
    }
    return SwipeToCloseWrapper(onClose: onShowStartup, child: scaffold);
  }
}

class _MoodFaceButton extends StatelessWidget {
  const _MoodFaceButton({
    required this.mood,
    required this.scene,
    required this.foreground,
    required this.lang,
    required this.onTap,
  });

  final MoodLevel mood;
  final Color scene;
  final Color foreground;
  final String lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Expandedで割り当てられた幅いっぱいの正円ボタンにして、間隔を詰めた分
    // ボタン自体が大きくなるようにする。アイコンサイズもボタンの直径に比例させる。
    return Semantics(
      label: mood.nameKey.tr(lang),
      button: true,
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final iconSize = constraints.maxWidth * 0.95;
            return Material(
              color: appAppearance.subtleFill(scene, 0.12),
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onTap,
                customBorder: const CircleBorder(),
                child: Center(
                  child: Icon(mood.icon, color: foreground, size: iconSize),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
