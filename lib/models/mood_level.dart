import 'package:flutter/material.dart';

/// 起動直後の気分選択で使う、5段階の元気度区分（0〜10スケール）。
enum MoodLevel {
  /// 最悪・へとへと（起点 1）。
  worst,

  /// いまいち（起点 3）。
  bad,

  /// 悪くはない・まあまあ（起点 5）。
  neutral,

  /// 良い・ぼちぼち（起点 7）。
  good,

  /// 快適・最高（起点 9）。
  great;

  /// カラー絵文字ではなく、単色（モノクロ）で描画できるピクトグラム。
  IconData get icon => switch (this) {
    MoodLevel.worst => Icons.sentiment_very_dissatisfied_rounded,
    MoodLevel.bad => Icons.sentiment_dissatisfied_rounded,
    MoodLevel.neutral => Icons.sentiment_neutral_rounded,
    MoodLevel.good => Icons.sentiment_satisfied_rounded,
    MoodLevel.great => Icons.sentiment_very_satisfied_rounded,
  };

  /// この顔マークを選んだときの元気度の起点（会話後の加減点の基準値）。
  int get genkiScore => switch (this) {
    MoodLevel.worst => 1,
    MoodLevel.bad => 3,
    MoodLevel.neutral => 5,
    MoodLevel.good => 7,
    MoodLevel.great => 9,
  };

  /// アクセシビリティ用の気分名（[AppStrings]キー）。
  String get nameKey => switch (this) {
    MoodLevel.worst => '気分_最悪',
    MoodLevel.bad => '気分_いまいち',
    MoodLevel.neutral => '気分_まあまあ',
    MoodLevel.good => '気分_良い',
    MoodLevel.great => '気分_最高',
  };
}
