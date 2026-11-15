import 'package:flutter/widgets.dart';

import '../app_globals.dart';

/// 設定（表示言語など）が変わったら、その場で描き直す。
///
/// 画面ごとに addListener を書くと付け忘れが起きるので、この mixin を付ける。
mixin RebuildOnAppSettings<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    appSettings.addListener(_rebuildOnSettings);
  }

  @override
  void dispose() {
    appSettings.removeListener(_rebuildOnSettings);
    super.dispose();
  }

  void _rebuildOnSettings() {
    if (mounted) setState(() {});
  }
}
