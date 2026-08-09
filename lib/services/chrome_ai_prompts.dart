import '../app_constants.dart';
import '../l10n/app_strings.dart';
import 'diary_storage.dart';

/// Chrome AIモードへ渡すプロンプト文を組み立てる。
abstract final class ChromeAiPrompts {
  /// 録音内容の元気度・日本語評点を診断してもらうプロンプト。
  /// [lang] はアプリの表示言語（ja / en / vi）。コメントも同じ言語で返すよう指示する。
  ///
  /// 元気度はAIにいきなり加減点を出させず、「ポジティブ度・ストレス度・疲労感・意欲」の
  /// 4項目を先に評価させる（osmWashabeの採点手法と同様、単一の主観判定より評価が
  /// ぶれにくいという狙い）。この4項目から実際の加減点を計算するのはアプリ側
  /// （[GenkiScoreCalculator.adjustmentFromDimensions]）で、AI自身には計算させない。
  static String recordingAnalysis({
    required String userText,
    required String lang,
  }) {
    final (:header, :speechHeading, :formatHeading, :reasonLanguage) =
        _recordingCopy(lang);

    return '$header\n'
        '\n'
        '$speechHeading\n'
        '$userText\n'
        '\n'
        '$formatHeading\n'
        '${_outputFormat(lang)}\n'
        '\n'
        '$reasonLanguage';
  }

  /// 日々の記録1件を、プロンプトに載せる1行に圧縮する（古い順に並べて渡す）。
  /// 文字数上限（Chrome AIモードへはURLクエリで渡すため）に収めるべく、理由文などは
  /// 含めず数値の推移だけに絞る。ラベルは回答してほしい言語に合わせて出し分ける
  /// （アプリの表示言語＝「元気度」「会話力」バッジと同じ翻訳キーを使う）。
  static String formatReviewLine(DiaryEntry entry, String lang) {
    final energyLabel = '元気度'.tr(lang);
    final skillLabel = '会話力'.tr(lang);
    final level = entry.japaneseLevel;
    final levelPart = level == null ? '' : ' $skillLabel$level';
    return '${entry.date.month}/${entry.date.day} $energyLabel${entry.genkiScore}$levelPart';
  }

  /// これまでの日記から、Chrome AIモードへ渡すアドバイス依頼プロンプトを組み立てる。
  /// アプリの表示言語（[lang]）に応じてプロンプトと回答言語を切り替える。
  /// URLクエリに載せる都合上の文字数上限に収まるよう、直近の記録を優先して残す。
  static String diaryReview(List<DiaryEntry> entries, String lang) {
    final lineBudget = AppConstants.diaryReviewLineBudget;
    final newestFirst = [...entries]..sort((a, b) => b.date.compareTo(a.date));

    final included = <DiaryEntry>[];
    var used = 0;
    for (final entry in newestFirst) {
      final line = formatReviewLine(entry, lang);
      final addedLength = line.length + 1;
      if (included.isNotEmpty && used + addedLength > lineBudget) break;
      included.add(entry);
      used += addedLength;
    }
    final oldestFirst = included.reversed.toList();
    final truncated = oldestFirst.length < entries.length;

    final lines = oldestFirst
        .map((entry) => formatReviewLine(entry, lang))
        .join('\n');

    final (:intro, :recordHeading, :truncatedNote) = switch (lang) {
      'en' => (
        intro:
            'Below is a trend of "Energy" (0-10) and "Conversation skill '
            'score" (1-10) that a user has recorded in a voice diary app. '
            'Based on this record, please give advice from the following '
            'two perspectives.\n'
            'Please use a warm, supportive tone rather than a condescending '
            'one. No need for a long preamble or greeting.\n'
            '\n'
            '- Things to keep in mind from the energy trend (e.g. staying '
            'steady, trending down) or changes\n'
            '- Suggestions for improving conversational skill\n'
            '\n'
            'Please answer in English.\n',
        recordHeading: '[Record (oldest first)]',
        truncatedNote: ' (most recent only)',
      ),
      'vi' => (
        intro:
            'Dưới đây là xu hướng "Năng lượng" (0-10) và "Điểm khả năng '
            'hội thoại" (1-10) mà một người dùng đã ghi lại trong ứng dụng '
            'nhật ký giọng nói. Dựa trên ghi chép này, hãy cho lời khuyên '
            'theo 2 góc độ sau.\n'
            'Hãy dùng giọng điệu ấm áp, đồng cảm, không bề trên. Không cần '
            'lời mở đầu hay chào hỏi dài dòng.\n'
            '\n'
            '- Những điều nên ghi nhớ từ xu hướng năng lượng (duy trì tốt, '
            'có xu hướng giảm, v.v.) hoặc sự thay đổi\n'
            '- Đề xuất để cải thiện khả năng hội thoại\n'
            '\n'
            'Hãy trả lời bằng tiếng Việt.\n',
        recordHeading: '[Ghi chép (từ cũ đến mới)]',
        truncatedNote: ' (chỉ gần đây)',
      ),
      _ => (
        intro:
            '以下は、あるユーザーがボイス日記アプリに記録してきた「元気度」（0〜10）と'
            '「会話力評点」（1〜10）の推移です。この記録を踏まえて、次の2つの観点から'
            'アドバイスをください。\n'
            '上から目線ではなく、寄り添うような言葉づかいでお願いします。'
            '長々とした前置きや挨拶は不要です。\n'
            '\n'
            '・元気度の傾向（良い状態が続いている、下降気味であるなど）や変化から、'
            '心に留めておいた方が良いこと\n'
            '・会話力向上に向けての提案\n'
            '\n'
            '回答は日本語でお願いします。\n',
        recordHeading: '【記録（古い順）】',
        truncatedNote: '（直近分のみ）',
      ),
    };

    return '$intro'
        '\n'
        '$recordHeading'
        '${truncated ? truncatedNote : ''}\n'
        '$lines';
  }

  static ({
    String header,
    String speechHeading,
    String formatHeading,
    String reasonLanguage,
  })
  _recordingCopy(String lang) => switch (lang) {
    'en' => (
      header:
          'You are a kind Japanese teacher. Analyze the [Speech] below.\n'
          'First, summarize in 1-2 sentences what the user talked about. '
          'Judging energy directly tends to be inconsistent, so next rate '
          'the 4 dimensions (Positivity / Stress level / Fatigue / '
          'Motivation) individually, and write the energy comment based on '
          'that. No long explanations or greetings.\n'
          'Keep the encouragement modest, and first empathize with how the '
          'user is feeling.',
      speechHeading: '[Speech]',
      formatHeading: '[Output format]',
      reasonLanguage: 'Write the comments in English.',
    ),
    'vi' => (
      header:
          'Bạn là một giáo viên tiếng Nhật dịu dàng. Hãy phân tích '
          '[Phát biểu] dưới đây.\n'
          'Trước tiên, hãy tóm tắt trong 1-2 câu nội dung người dùng đã nói. '
          'Vì đánh giá năng lượng trực tiếp dễ thiếu nhất quán, tiếp theo '
          'hãy đánh giá riêng 4 khía cạnh (Mức độ tích cực / Mức độ căng '
          'thẳng / Mức độ mệt mỏi / Động lực), rồi viết nhận xét năng lượng '
          'dựa trên đó. Không cần giải thích dài hay lời chào.\n'
          'Hãy hạn chế lời động viên, và trước tiên hãy đồng cảm với '
          'cảm xúc của người dùng.',
      speechHeading: '[Phát biểu]',
      formatHeading: '[Định dạng đầu ra]',
      reasonLanguage: 'Hãy viết nhận xét bằng tiếng Việt.',
    ),
    _ => (
      header:
          'あなたは優しい日本語教師です。以下の【発言】を分析してください。\n'
          'まず、話してくれた内容を1〜2文で要約してください。'
          'いきなり元気度を判断すると評価がぶれやすいため、次に'
          '「ポジティブ度」「ストレス度」「疲労感」「意欲」の4項目をそれぞれ評価し、'
          'それを踏まえて元気度コメントを書いてください。'
          '長々とした解説や挨拶は不要です。\n'
          '励ましは控えめにし、まずは相手の気持ちに共感するトーンで書いてください。',
      speechHeading: '【発言】',
      formatHeading: '【出力フォーマット】',
      reasonLanguage: 'コメントは日本語で書いてください。',
    ),
  };

  static String _outputFormat(String lang) => switch (lang) {
    'en' =>
      '''
Summary: (1-2 sentences about what the user talked about)
Positivity: (integer 0-4; 0 = very negative, 4 = very positive)
Stress level: (integer 0-4; 0 = no stress, 4 = very stressed)
Fatigue: (integer 0-4; 0 = not tired, 4 = very tired)
Motivation: (integer 0-4; 0 = low motivation, 4 = highly motivated)
Energy comment: (one empathetic sentence)
Japanese score: (1-10, same as JSST scale; 10 is best)
Conversation comment: (one sentence)''',
    'vi' =>
      '''
Tóm tắt: (1-2 câu về nội dung người dùng đã nói)
Mức độ tích cực: (số nguyên 0-4; 0 = rất tiêu cực, 4 = rất tích cực)
Mức độ căng thẳng: (số nguyên 0-4; 0 = không căng thẳng, 4 = rất căng thẳng)
Mức độ mệt mỏi: (số nguyên 0-4; 0 = không mệt, 4 = rất mệt)
Động lực: (số nguyên 0-4; 0 = động lực thấp, 4 = rất có động lực)
Nhận xét năng lượng: (một câu đồng cảm)
Điểm tiếng Nhật: (1-10, cùng thang JSST; 10 là cao nhất)
Nhận xét khả năng hội thoại: (một câu)''',
    _ =>
      '''
要約: (話してくれた内容を1〜2文で)
ポジティブ度: (0〜4の整数。0=とても後ろ向き、4=とても前向き)
ストレス度: (0〜4の整数。0=ストレスなし、4=強いストレス)
疲労感: (0〜4の整数。0=疲れていない、4=とても疲れている)
意欲: (0〜4の整数。0=意欲が低い、4=とても意欲的)
元気度コメント: (共感を込めた1文。励ましは控えめに)
日本語評点: (JSSTと同じ1〜10の数値。10が最高)
会話力コメント: (1文)''',
  };
}
