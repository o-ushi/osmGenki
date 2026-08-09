/// 顔マーク（起点）と Chrome AI の加減点から、最終元気度（0〜10）を求める。
abstract final class GenkiScoreCalculator {
  static const minScore = 0;
  static const maxScore = 10;

  /// [baseline]（1/3/5/7/9）に [adjustment] を加え、0〜10に収める。
  static int finalScore({required int baseline, required int adjustment}) =>
      (baseline + adjustment).clamp(minScore, maxScore);

  /// Chrome AIにいきなり加減点を判断させると評価がぶれやすいため、
  /// 「ポジティブ度・ストレス度・疲労感・意欲」（各0〜4、2が中央＝変化なし）の
  /// 4項目から加減点を計算する。ポジティブ度・意欲はプラス方向、
  /// ストレス度・疲労感はマイナス方向に働く。
  /// 加減点は-8〜+8のフルスイングにする（スケールダウンしない）。これにより、
  /// 例えば起点9（最高）でも4項目すべてが最悪なら1まで下がる、起点1（最低）でも
  /// 4項目すべてが最良なら9まで上がるなど、内容次第で起点を大きく覆せるようにする。
  static int adjustmentFromDimensions({
    required int positivity,
    required int stress,
    required int fatigue,
    required int motivation,
  }) {
    return (positivity - 2) - (stress - 2) - (fatigue - 2) + (motivation - 2);
  }

  /// 内訳表示用。プラスなら「+2」、ゼロは「0」、マイナスは「-3」。
  static String formatAdjustment(int adjustment, String languageCode) {
    if (adjustment > 0) return '+$adjustment';
    return '$adjustment';
  }
}
