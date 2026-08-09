// osmWashabeのJSST採点手法（lib/services/jsst_scoring_service.dart）から移植した
// データモデル一式。「待遇表現」「テキストタイプ」「流暢さ」の3軸を近似する
// ルールベース判定で、文法・発音・公式の総合レベルは判定しない。

/// 1回の発話区切り（osm_genkiでは録音開始から終了までの1サイクル）のSTT認識結果。
class TranscriptChunk {
  const TranscriptChunk({required this.text, required this.recognizedAt});

  final String text;
  final DateTime recognizedAt;
}

/// 待遇表現カテゴリ（尊敬語/謙譲語/丁寧語）ごとの検出結果。
class KeigoCategoryResult {
  const KeigoCategoryResult({
    required this.category,
    required this.matchedExpressions,
  });

  final String category;
  final Set<String> matchedExpressions;
}

/// JSST「待遇表現」軸の近似スコア。
class KeigoAnalysis {
  const KeigoAnalysis({required this.categories, required this.varietyScore});

  final List<KeigoCategoryResult> categories;

  /// 使用が検出されたカテゴリ数（0〜3）。JSST待遇表現軸の粗い代理指標。
  final int varietyScore;
}

/// 発話単位の構造分類。
enum SentenceUnitType { simple, compound, complex }

/// JSST「テキストタイプ」軸の近似スコア。
class SentenceComplexityAnalysis {
  const SentenceComplexityAnalysis({
    required this.totalUnits,
    required this.complexUnitCount,
    required this.complexityRatio,
  });

  final int totalUnits;
  final int complexUnitCount;

  /// (重文+複文の発話単位数) / 全発話単位数
  final double complexityRatio;
}

/// 1回の発話フェーズにおけるSTTセッションの時間枠。
///
/// osmWashabeはタイマーで与えられた固定秒数（45/60秒）を使うが、osm_genkiは
/// 自由発話で固定の持ち時間が無いため、実際にかかった時間（録音開始〜最終認識）
/// を「持ち時間」として渡す（呼び出し側で計算する）。
class SpeechSessionContext {
  const SpeechSessionContext({
    required this.allottedSeconds,
    this.startedAt,
    this.endedAt,
  });

  final int allottedSeconds;
  final DateTime? startedAt;
  final DateTime? endedAt;
}

/// JSST「流暢さ／時間の使い方」軸の近似スコア。
/// 書き起こしだけでは分からない沈黙・発話量を、チャンクの時刻と文字数から推定する。
class FluencyAnalysis {
  const FluencyAnalysis({
    required this.allottedSeconds,
    required this.capturedSeconds,
    required this.timeToFirstSpeechSeconds,
    required this.estimatedSpeechSeconds,
    required this.estimatedSilenceSeconds,
    required this.silenceRatio,
    required this.timeUtilization,
    required this.spokenCharacterCount,
    required this.charactersPerAllottedMinute,
    required this.longPauseCount,
    required this.referenceLevel,
  });

  factory FluencyAnalysis.unavailable({required int allottedSeconds}) {
    return FluencyAnalysis(
      allottedSeconds: allottedSeconds,
      capturedSeconds: 0,
      timeToFirstSpeechSeconds: 0,
      estimatedSpeechSeconds: 0,
      estimatedSilenceSeconds: 0,
      silenceRatio: 0,
      timeUtilization: 0,
      spokenCharacterCount: 0,
      charactersPerAllottedMinute: 0,
      longPauseCount: 0,
      referenceLevel: 1,
    );
  }

  final int allottedSeconds;
  final double capturedSeconds;
  final double timeToFirstSpeechSeconds;
  final double estimatedSpeechSeconds;
  final double estimatedSilenceSeconds;
  final double silenceRatio;
  final double timeUtilization;
  final int spokenCharacterCount;
  final double charactersPerAllottedMinute;
  final int longPauseCount;

  /// 1〜4の参考レベル（JSST「1〜2」「3〜4」「5〜6」「7〜」の帯域に相当）。
  final int referenceLevel;
}

/// 1回の発話フェーズに対する採点結果（永続化はしない）。
class ScoringResult {
  ScoringResult({
    required this.transcriptChunks,
    required this.fullTranscript,
    required this.keigo,
    required this.complexity,
    required this.fluency,
    this.session,
  }) : generatedAt = DateTime.now();

  final List<TranscriptChunk> transcriptChunks;
  final String fullTranscript;
  final KeigoAnalysis keigo;
  final SentenceComplexityAnalysis complexity;
  final FluencyAnalysis fluency;
  final SpeechSessionContext? session;
  final DateTime generatedAt;
}

/// [FluencyAnalysis]のうち、日記エントリに永続化する指標のスナップショット。
/// osmWashabeの採点結果シート「時間の使い方」と同じ項目。
class FluencySnapshot {
  const FluencySnapshot({
    required this.allottedSeconds,
    required this.spokenCharacterCount,
    required this.charactersPerAllottedMinute,
    required this.timeUtilization,
    required this.silenceRatio,
    required this.estimatedSpeechSeconds,
    required this.longPauseCount,
  });

  factory FluencySnapshot.fromAnalysis(FluencyAnalysis analysis) {
    return FluencySnapshot(
      allottedSeconds: analysis.allottedSeconds,
      spokenCharacterCount: analysis.spokenCharacterCount,
      charactersPerAllottedMinute: analysis.charactersPerAllottedMinute,
      timeUtilization: analysis.timeUtilization,
      silenceRatio: analysis.silenceRatio,
      estimatedSpeechSeconds: analysis.estimatedSpeechSeconds,
      longPauseCount: analysis.longPauseCount,
    );
  }

  final int allottedSeconds;
  final int spokenCharacterCount;
  final double charactersPerAllottedMinute;
  final double timeUtilization;
  final double silenceRatio;
  final double estimatedSpeechSeconds;
  final int longPauseCount;

  Map<String, dynamic> toJson() => {
    'allottedSeconds': allottedSeconds,
    'spokenCharacterCount': spokenCharacterCount,
    'charactersPerAllottedMinute': charactersPerAllottedMinute,
    'timeUtilization': timeUtilization,
    'silenceRatio': silenceRatio,
    'estimatedSpeechSeconds': estimatedSpeechSeconds,
    'longPauseCount': longPauseCount,
  };

  factory FluencySnapshot.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) => switch (v) {
      double d => d,
      num n => n.toDouble(),
      String s => double.parse(s),
      _ => 0,
    };
    int toInt(dynamic v) => switch (v) {
      int i => i,
      num n => n.round(),
      String s => int.parse(s),
      _ => 0,
    };
    return FluencySnapshot(
      allottedSeconds: toInt(json['allottedSeconds']),
      spokenCharacterCount: toInt(json['spokenCharacterCount']),
      charactersPerAllottedMinute: toDouble(
        json['charactersPerAllottedMinute'],
      ),
      timeUtilization: toDouble(json['timeUtilization']),
      silenceRatio: toDouble(json['silenceRatio']),
      estimatedSpeechSeconds: toDouble(json['estimatedSpeechSeconds']),
      longPauseCount: toInt(json['longPauseCount']),
    );
  }
}
