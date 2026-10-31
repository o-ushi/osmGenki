import 'package:flutter/material.dart';

import '../app_globals.dart';
import '../data/app_languages.dart';
import '../l10n/app_strings.dart';
import 'language_picker.dart';

/// 現在の表示言語の国旗だけを見せるボタン。タップすると言語選択シートを開く。
/// [StartupScreen]など、設定画面を経由せず素早く言語を切り替えたい場面で使う。
class LanguageFlagButton extends StatelessWidget {
  const LanguageFlagButton({super.key});

  String get _currentFlag {
    for (final (code, _, flag) in appLanguages) {
      if (code == appSettings.language) return flag;
    }
    return appLanguages.first.$3;
  }

  @override
  Widget build(BuildContext context) {
    // const で置かれても言語変更で国旗が切り替わるよう、自分で設定を購読する。
    return ListenableBuilder(
      listenable: appSettings,
      builder: (context, _) => _buildButton(context),
    );
  }

  Widget _buildButton(BuildContext context) {
    return Tooltip(
      message: '言語'.tr(appSettings.language),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => showLanguagePickerSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text(_currentFlag, style: const TextStyle(fontSize: 26)),
        ),
      ),
    );
  }
}
