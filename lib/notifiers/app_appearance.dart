import 'package:flutter/material.dart';

import '../models/appearance_models.dart';
import '../theme/app_colors.dart';
import '../theme/appearance_resolver.dart';

/// アプリ全体で固定の既定外観（標準テーマ・パステル枠・方眼＋ドット）。
/// シーン色は端末の夜間モードに依存しない（osmGradusと同じ）。
const appAppearance = AppAppearance();

class AppAppearance {
  const AppAppearance();

  Color get accentColor => AppearanceResolver.accentColor;

  /// 固定シーン色。
  Color get sceneColor => AppearanceResolver.sceneColor;

  /// シーン色の輝度から Material の明暗を決定する（OSの明暗ではない）。
  Brightness get effectiveColorScheme =>
      isLightBackground(sceneColor) ? Brightness.light : Brightness.dark;

  FrameResolvedStyle resolvedFrameStyle() => AppearanceResolver.pastelFrame();

  Color readableAccent(Color surface) =>
      AppearanceResolver.readableAccent(accentColor, surface);

  Color subtleFill(Color surface, double opacity) {
    final palette = AppColors.current;
    if (isLightBackground(surface)) {
      return palette.textOnCardPrimary.withValues(alpha: opacity * 0.55);
    }
    return palette.textOnScenePrimary.withValues(alpha: opacity);
  }

  bool isLightBackground(Color color) =>
      AppearanceResolver.isLightSurface(color);

  Color foregroundOn(Color background) =>
      AppearanceResolver.primaryTextOn(background);

  Color mutedOn(Color background) =>
      AppearanceResolver.secondaryTextOn(background);
}
