/// [JsstScoringService]のルールベース判定（1〜4、判定不能ならnull）と、
/// Chrome AIモード自身が申告する日本語評点（1〜10）を合成し、
/// JSSTと同じ1〜10のスケールで最終的な日本語評点を算出する。
///
/// Chrome AIの値はスケール変換せずそのまま使う。ルールベース側は4段階
/// （1〜2 / 3〜4 / 5〜6 / 7〜）を、それぞれ10点満点上の代表値 2 / 4 / 6 / 8
/// に写してから合成する（最上段は7〜のため、ルールベース単独では10にはならない）。
abstract final class JsstScoreCombiner {
  /// ルールベース判定（文章内容・タイミングのみを見る客観的な近似値）を
  /// Chrome AI自身の主観判定より重く見る。
  static const double ruleBasedWeight = 0.6;
  static const double chromeAiWeight = 0.4;

  /// [ruleBasedLevel1to4]は発話が短すぎる・日本語として不十分な場合に、
  /// [chromeAiLevel1to10]はChrome AIの解析結果に評点が含まれなかった場合に、
  /// それぞれnullになりうる。両方揃っていれば重み付き平均、片方だけなら
  /// その値のみを返す。両方nullなら評価不能としてnullを返す。
  static int? combine({
    required int? ruleBasedLevel1to4,
    required int? chromeAiLevel1to10,
  }) {
    final chromeAiLevel = chromeAiLevel1to10 == null
        ? null
        : _clampToJsstScale(chromeAiLevel1to10);

    final ruleBasedLevel = ruleBasedLevel1to4 == null
        ? null
        : _ruleBasedLevelOn10Scale(ruleBasedLevel1to4);

    if (ruleBasedLevel == null && chromeAiLevel == null) return null;
    if (ruleBasedLevel == null) return chromeAiLevel;
    if (chromeAiLevel == null) return ruleBasedLevel;

    final blended =
        ruleBasedLevel * ruleBasedWeight + chromeAiLevel * chromeAiWeight;
    return _clampToJsstScale(blended.round());
  }

  /// Chrome AIの判定を混ぜない、osmWashabeのルールベース判定そのままの帯域ラベル。
  /// osmWashabeは1〜10の連続値ではなく「1〜2/3〜4/5〜6/7〜」の4段階でしか判定しないため、
  /// 10点満点の数値に変換せずこの帯域文字列で表示する。
  /// [ruleBasedLevel1to4]がnull（発話が短すぎる等）ならnullを返す。
  static String? ruleBasedBandLabel(int? ruleBasedLevel1to4) {
    if (ruleBasedLevel1to4 == null) return null;
    final level = ruleBasedLevel1to4 < 1
        ? 1
        : (ruleBasedLevel1to4 > 4 ? 4 : ruleBasedLevel1to4);
    return switch (level) {
      1 => '1〜2',
      2 => '3〜4',
      3 => '5〜6',
      _ => '7〜',
    };
  }

  /// osmWashabeのJSST帯域（1〜2/3〜4/5〜6/7〜）を10点満点上の代表値に写す。
  static int _ruleBasedLevelOn10Scale(int ruleBasedLevel1to4) {
    final level = ruleBasedLevel1to4 < 1
        ? 1
        : (ruleBasedLevel1to4 > 4 ? 4 : ruleBasedLevel1to4);
    return switch (level) {
      1 => 2,
      2 => 4,
      3 => 6,
      _ => 8,
    };
  }

  static int _clampToJsstScale(int value) =>
      value < 1 ? 1 : (value > 10 ? 10 : value);
}
