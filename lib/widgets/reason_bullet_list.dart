import 'package:flutter/material.dart';

/// 理由テキスト（1行1コメント）を表示する。コメントは1文のみになったため
/// 番号付けはしない。保存済みの旧データ（複数行の箇条書き）が残っていても、
/// 先頭の箇条書きマーカー（-・*など）を取り除いた上でそのまま1行ずつ表示する。
class ReasonBulletList extends StatelessWidget {
  const ReasonBulletList({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) => line.replaceFirst(RegExp(r'^[-・*]+\s*'), ''))
        .toList();
    return Text(
      lines.join('\n'),
      style: TextStyle(color: color, fontSize: 14, height: 1.5),
    );
  }
}
