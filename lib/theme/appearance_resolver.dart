import 'package:flutter/material.dart';

import '../models/appearance_models.dart';
import 'app_colors.dart';

/// [AppColors.current] を土台にした外観色・コントラスト補助（ユーザー向けテーマ選択なし）。
/// シーン色は osmGradus と同様、端末の明暗設定に依存せず常に固定。
abstract final class AppearanceResolver {
  static Color get brandBlue => AppColors.current.scene;
  static Color get accentColor => AppColors.current.accentColor;

  /// 固定のシーン背景色（昼夜で変えない）。
  static Color get sceneColor => AppColors.current.scene;

  /// 固定既定のパステル枠。
  static FrameResolvedStyle pastelFrame() {
    final palette = AppColors.current;
    return FrameResolvedStyle(
      cardFill: palette.cardFill,
      cardBorder: palette.cardBorder,
      accentStrip: palette.cardAccent,
      borderWidth: 1.0,
      readablePrimaryText: palette.textOnCardPrimary,
      readableSecondaryText: palette.textOnCardSecondary,
      usesLightText: false,
    );
  }

  /// 背景色が「明るい」と判定するかどうか。単純な輝度しきい値だと
  /// 標準の青（#007AFF）のような鮮やかな中〜暗色を誤って「明るい」と
  /// 判定してしまうため、FlutterのWCAG準拠の判定式に委譲する。
  static bool isLightSurface(Color color) =>
      ThemeData.estimateBrightnessForColor(color) == Brightness.light;

  static Color primaryTextOn(Color fill) {
    final palette = AppColors.current;
    return isLightSurface(fill)
        ? palette.textOnCardPrimary
        : palette.textOnScenePrimary;
  }

  static Color secondaryTextOn(Color fill) {
    final palette = AppColors.current;
    return isLightSurface(fill)
        ? palette.textOnCardSecondary
        : palette.textOnSceneSecondary;
  }

  /// [fill] の上に乗せる読みやすい前景色。
  static Color onFill(Color fill) => isLightSurface(fill)
      ? AppColors.current.textOnCardPrimary
      : AppColors.current.onAccent;

  static Color readableAccent(Color accent, Color surface) {
    if (isLightSurface(surface)) return accent;
    return Color.lerp(accent, AppColors.current.onAccent, 0.25) ?? accent;
  }
}
