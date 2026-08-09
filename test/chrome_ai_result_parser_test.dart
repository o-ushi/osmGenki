import 'package:flutter_test/flutter_test.dart';
import 'package:osm_genki/services/chrome_ai_result_parser.dart';

void main() {
  group('ChromeAiResultParser', () {
    test('parses Japanese labels for genki dimensions and japanese level', () {
      const text = '''
要約: 今日は仕事が忙しかったが前向きに話した。
ポジティブ度: 3
ストレス度: 2
疲労感: 1
意欲: 3
元気度コメント: 前向きな調子が感じられる。
日本語評点: 7
会話力コメント: 自然な言い回しが多い。
''';
      final parsed = ChromeAiResultParser.parse(text);
      expect(parsed.positivity, 3);
      expect(parsed.stress, 2);
      expect(parsed.fatigue, 1);
      expect(parsed.motivation, 3);
      expect(parsed.japaneseLevel, 7);
      expect(parsed.summary, contains('仕事'));
      expect(parsed.genkiReason, contains('前向き'));
      expect(parsed.japaneseReason, contains('言い回し'));
    });

    test('parses English labels including energy adjustment fallback', () {
      const text = '''
Summary: Talked about a calm weekend.
Energy adjustment: +2
Japanese score: 8
Energy comment: Sounded rested.
Conversation comment: Clear structure.
''';
      final parsed = ChromeAiResultParser.parse(text);
      expect(parsed.genkiAdjustment, 2);
      expect(parsed.japaneseLevel, 8);
      expect(parsed.summary, contains('weekend'));
      expect(parsed.genkiReason, contains('rested'));
      expect(parsed.japaneseReason, contains('structure'));
    });

    test('parses absolute energy and clamps japanese level', () {
      const text = '''
元気度: 9
日本語レベル: 15
''';
      final parsed = ChromeAiResultParser.parse(text);
      expect(parsed.genkiAbsolute, 9);
      expect(parsed.genkiAdjustment, isNull);
      expect(parsed.japaneseLevel, 10);
    });
  });
}
