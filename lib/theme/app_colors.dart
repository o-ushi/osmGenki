import 'package:flutter/material.dart';

/// osmGradusと同一の固定カラーパレット。
///
/// シーン背景・サブページ背景・カード面・アクセントはデザインシステムとして固定。
/// ユーザー向けのテーマ／外観切り替えは持たない。
class AppPalette {
  const AppPalette({
    required this.scene,
    required this.subpageBackground,
    required this.cardFill,
    required this.cardBorder,
    required this.cardAccent,
    required this.accentColor,
    required this.onAccent,
    required this.textOnScenePrimary,
    required this.textOnSceneSecondary,
    required this.textOnSubpagePrimary,
    required this.textOnSubpageSecondary,
    required this.textOnCardPrimary,
    required this.textOnCardSecondary,
  });

  /// メイン画面（マイク・ダッシュボード・日記一覧・気分選択・スタートアップ）の背景色。
  final Color scene;

  /// 設定・ヘルプ・プライバシーなどサブ画面の背景色（iOS標準グレー）。
  final Color subpageBackground;

  /// シーン上に浮かぶカード（フレームカード等）／設定セクションカードの塗り色。
  final Color cardFill;

  /// カードの枠線色。
  final Color cardBorder;

  /// カードのアクセントストライプ色。
  final Color cardAccent;

  /// ボタン等のメインアクセントカラー。
  final Color accentColor;

  /// [accentColor] で塗られた面の上に乗せる文字・アイコン色。
  final Color onAccent;

  /// [scene] の上に直接乗せる文字色。
  final Color textOnScenePrimary;
  final Color textOnSceneSecondary;

  /// [subpageBackground] の上に乗せる文字色。
  final Color textOnSubpagePrimary;
  final Color textOnSubpageSecondary;

  /// [cardFill] の上に乗せる文字色。
  final Color textOnCardPrimary;
  final Color textOnCardSecondary;

  static const flatDefault = AppPalette(
    scene: Color(0xFF3D5993),
    subpageBackground: Color(0xFFF2F2F7),
    cardFill: Color(0xFFFFFAF2),
    cardBorder: Color(0xFFF5C799),
    cardAccent: Color(0xFFFF9933),
    accentColor: Color(0xFF007AFF),
    onAccent: Color(0xFFFFFFFF),
    textOnScenePrimary: Color(0xFFFFFFFF),
    textOnSceneSecondary: Color(0xB3FFFFFF),
    textOnSubpagePrimary: Color(0xFF1A1A1F),
    textOnSubpageSecondary: Color(0xFF61616B),
    textOnCardPrimary: Color(0xFF1A1A1F),
    textOnCardSecondary: Color(0xFF61616B),
  );
}

class AppColors {
  AppColors._();

  /// アプリ全体で使う固定パレット。
  static const AppPalette current = AppPalette.flatDefault;
}

/// 録音中など「強調」を示す色（テーマ非依存の意味色）。
const Color kRecordingColor = Color(0xFFFF3B30);

/// 「貼り付け待ち」ボタンを示す色（テーマ非依存の意味色）。
const Color kPasteReadyColor = Color(0xFF34C759);
