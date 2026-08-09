import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/surface_theme.dart';

/// ヘルプ・設定など、スワイプで閉じるサブ画面用の共通骨格。
/// 背景・AppBar・文字は常に [AppColors.current.subpageBackground] 系に固定し、
/// 親（シーン側）や端末のダークモードのテーマを継承しない。
class GenkiSubpageScaffold extends StatelessWidget {
  const GenkiSubpageScaffold({
    super.key,
    this.title = '',
    required this.body,
    this.actions,
    this.leading,
    this.hideLeading = true,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;

  /// true のとき左上の戻るボタンを出さない（下/右スワイプで閉じる想定）。
  /// Androidではシステム戻るとあわせて常に戻るボタンを出す。
  final bool hideLeading;

  @override
  Widget build(BuildContext context) {
    final effectiveHideLeading = Platform.isAndroid ? false : hideLeading;
    final palette = AppColors.current;
    final base = SurfaceTheme.subpage(context);
    final themeData = base.copyWith(
      useMaterial3: true,
      brightness: Brightness.light,
      appBarTheme: base.appBarTheme.copyWith(
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: palette.accentColor,
        brightness: Brightness.light,
        surface: palette.cardFill,
        onSurface: palette.textOnCardPrimary,
      ),
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Theme(
        data: themeData,
        child: Scaffold(
          backgroundColor: palette.subpageBackground,
          appBar: AppBar(
            automaticallyImplyLeading: !effectiveHideLeading,
            leading: effectiveHideLeading
                ? null
                : (leading ??
                      (Navigator.canPop(context)
                          ? const BackButton()
                          : null)),
            leadingWidth: effectiveHideLeading ? 0 : null,
            title: Text(title),
            actions: actions,
          ),
          body: body,
        ),
      ),
    );
  }
}
