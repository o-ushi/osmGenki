import 'genki_score_calculator.dart';

/// Chrome AIの解析結果テキストをパースする（日本語・英語・ベトナム語のラベルに対応）。
class ChromeAiParsedResult {
  const ChromeAiParsedResult({
    this.genkiAdjustment,
    this.genkiAbsolute,
    this.positivity,
    this.stress,
    this.fatigue,
    this.motivation,
    this.japaneseLevel,
    this.summary,
    this.genkiReason,
    this.japaneseReason,
  });

  /// 旧形式（AIが直接出す元気度の加減点）。[positivity]等の4項目が揃わなかった
  /// 場合のフォールバックとしてのみ使う。
  final int? genkiAdjustment;
  final int? genkiAbsolute;

  /// 元気度を構成する4項目（各0〜4）。すべて揃っている場合、実際の加減点は
  /// AIにではなく[GenkiScoreCalculator.adjustmentFromDimensions]で計算する。
  final int? positivity;
  final int? stress;
  final int? fatigue;
  final int? motivation;

  final int? japaneseLevel;

  /// AIが元気度を判定する前に書く、話した内容の1〜2文の要約。
  final String? summary;
  final String? genkiReason;
  final String? japaneseReason;

  /// [positivity]〜[motivation]の4項目がすべて揃っているか。
  bool get hasAllDimensions =>
      positivity != null && stress != null && fatigue != null && motivation != null;
}

abstract final class ChromeAiResultParser {
  static const _adjustmentLabels = [
    '元気度の加減点',
    'Energy adjustment',
    'Điều chỉnh năng lượng',
  ];

  static const _absoluteLabels = ['元気度', 'Energy', 'Năng lượng'];

  static const _positivityLabels = ['ポジティブ度', 'Positivity', 'Mức độ tích cực'];

  static const _stressLabels = ['ストレス度', 'Stress level', 'Mức độ căng thẳng'];

  static const _fatigueLabels = ['疲労感', 'Fatigue', 'Mức độ mệt mỏi'];

  static const _motivationLabels = ['意欲', 'Motivation', 'Động lực'];

  static const _japaneseLevelLabels = [
    '日本語評点',
    '日本語レベル',
    'Japanese score',
    'Điểm tiếng Nhật',
  ];

  /// AIが元気度判定の前に書く、話した内容の1〜2文の要約。
  static const _summaryLabels = ['要約', 'Summary', 'Tóm tắt'];

  static const _genkiReasonLabels = [
    '元気度コメント',
    '元気度の理由',
    'Energy comment',
    'Reasons for energy adjustment',
    'Nhận xét năng lượng',
    'Lý do điều chỉnh năng lượng',
  ];

  static const _japaneseReasonLabels = [
    '会話力コメント',
    '日本語評点の理由',
    'Conversation comment',
    'Reasons for Japanese score',
    'Nhận xét khả năng hội thoại',
    'Lý do điểm tiếng Nhật',
  ];

  /// すべてのラベルの一覧。AIが改行を省略して1行に詰めて返してきた場合に、
  /// コメント抽出（[_extractReason]）が次のラベルの手前で止まれるようにするため。
  static const _allLabels = [
    ..._adjustmentLabels,
    ..._absoluteLabels,
    ..._positivityLabels,
    ..._stressLabels,
    ..._fatigueLabels,
    ..._motivationLabels,
    ..._japaneseLevelLabels,
    ..._summaryLabels,
    ..._genkiReasonLabels,
    ..._japaneseReasonLabels,
  ];

  static ChromeAiParsedResult parse(String text) {
    final adjustmentMatch = _firstMatch(
      text,
      _labelPattern(_adjustmentLabels, r'([+\-＋－]?\s*\d{1,2})'),
    );
    final absoluteMatch = adjustmentMatch == null
        ? _firstMatch(text, _labelPattern(_absoluteLabels, r'(\d{1,2})'))
        : null;
    final levelMatch = _firstMatch(
      text,
      _labelPattern(_japaneseLevelLabels, r'(\d{1,2})'),
    );
    final positivityMatch = _firstMatch(
      text,
      _labelPattern(_positivityLabels, r'(\d)'),
    );
    final stressMatch = _firstMatch(text, _labelPattern(_stressLabels, r'(\d)'));
    final fatigueMatch = _firstMatch(
      text,
      _labelPattern(_fatigueLabels, r'(\d)'),
    );
    final motivationMatch = _firstMatch(
      text,
      _labelPattern(_motivationLabels, r'(\d)'),
    );

    return ChromeAiParsedResult(
      genkiAdjustment: _parseAdjustment(adjustmentMatch),
      genkiAbsolute: _parseClamped(
        absoluteMatch,
        GenkiScoreCalculator.minScore,
        GenkiScoreCalculator.maxScore,
      ),
      positivity: _parseClamped(positivityMatch, 0, 4),
      stress: _parseClamped(stressMatch, 0, 4),
      fatigue: _parseClamped(fatigueMatch, 0, 4),
      motivation: _parseClamped(motivationMatch, 0, 4),
      japaneseLevel: _parseClamped(levelMatch, 1, 10),
      summary: _extractReason(text, _summaryLabels, _positivityLabels),
      genkiReason: _extractReason(text, _genkiReasonLabels, _japaneseReasonLabels),
      japaneseReason: _extractReason(text, _japaneseReasonLabels, const []),
    );
  }

  /// コメント欄を抽出する。新形式（「ラベル: 1文コメント」の1行）をまず試し、
  /// 見つからなければ旧形式（ラベル行の次から始まる箇条書きブロック）にフォールバック
  /// する（AIが指示を無視して旧形式で返してきた場合の保険）。
  static String? _extractReason(
    String text,
    List<String> startLabels,
    List<String> endLabels,
  ) {
    // AIが改行を省略し「元気度コメント: 〜。日本語評点: 8」のように1行へ詰めて
    // 返してくることがあるため、素の`(.+)`だと次のラベルまで丸ごと拾ってしまう。
    // 次のラベルの手前（または改行・文末）で止まるように先読みで区切る。
    final otherLabels = _allLabels.map(RegExp.escape).join('|');
    final singleLineMatch = _firstMatch(
      text,
      _labelPattern(startLabels, '(.+?)(?=\\n|(?:$otherLabels)\\s*[:：]|\$)'),
    );
    final singleLine = singleLineMatch?.group(1)?.trim();
    if (singleLine != null && singleLine.isNotEmpty) {
      return singleLine;
    }
    return _extractReasonBlock(text, startLabels, endLabels);
  }

  static String _labelPattern(List<String> labels, String valuePattern) {
    final escaped = labels.map(RegExp.escape).join('|');
    return '(?:$escaped)\\s*[:：]\\s*$valuePattern';
  }

  static RegExpMatch? _firstMatch(String text, String pattern) {
    return RegExp(pattern).firstMatch(text);
  }

  static int? _parseAdjustment(RegExpMatch? match) {
    if (match == null) return null;
    final raw = match
        .group(1)!
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('＋', '+')
        .replaceAll('－', '-');
    return int.tryParse(raw);
  }

  static int? _parseClamped(RegExpMatch? match, int min, int max) {
    final raw = match == null ? null : int.tryParse(match.group(1)!);
    if (raw == null) return null;
    return raw.clamp(min, max);
  }

  static String? _extractReasonBlock(
    String text,
    List<String> startLabels,
    List<String> endLabels,
  ) {
    var startIndex = -1;
    for (final label in startLabels) {
      final index = text.indexOf(label);
      if (index != -1 && (startIndex == -1 || index < startIndex)) {
        startIndex = index;
      }
    }
    if (startIndex == -1) return null;

    final contentStart = text.indexOf('\n', startIndex);
    if (contentStart == -1) return null;

    var endIndex = text.length;
    for (final label in endLabels) {
      final found = text.indexOf(label, contentStart);
      if (found != -1 && found < endIndex) endIndex = found;
    }

    final lines = text
        .substring(contentStart, endIndex)
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) => line.replaceFirst(RegExp(r'^[-・*]+\s*'), ''))
        .toList();
    return lines.isEmpty ? null : lines.join('\n');
  }
}
