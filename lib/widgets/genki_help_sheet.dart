import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// [GenkiHelpSheet]の1行分。[text]の中の`{{icon}}`という文字列を[icon]の
/// アイコンに差し替えて描画する（プレースホルダーは1行につき最大1つ）。
/// [indent]をtrueにすると、見出し行の下にぶら下がる子項目として字下げする。
/// [header]をtrueにすると、セクション見出し（「<グラフ>」等）として太字で描画する。
class GenkiHelpLine {
  const GenkiHelpLine({
    required this.text,
    this.icon,
    this.indent = false,
    this.header = false,
  });

  final String text;
  final IconData? icon;
  final bool indent;
  final bool header;
}

/// osmGradusの`LayerHelpSheet`に相当。各画面の[•••]ボタン長押しで表示する
/// 使い方シート。つまみ付きの角丸ボトムシートで統一する。
class GenkiHelpSheet extends StatelessWidget {
  const GenkiHelpSheet({super.key, required this.title, required this.lines});

  final String title;
  final List<GenkiHelpLine> lines;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required List<GenkiHelpLine> lines,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.current.cardFill,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => GenkiHelpSheet(title: title, lines: lines),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fg = AppColors.current.textOnCardPrimary;
    final handleColor = AppColors.current.cardBorder;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: handleColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: fg,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final line in lines)
                        _HelpLineView(line: line, foreground: fg),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpLineView extends StatelessWidget {
  const _HelpLineView({required this.line, required this.foreground});

  final GenkiHelpLine line;
  final Color foreground;

  /// 行頭の連番バッジ（1️⃣〜9️⃣、絵文字の合字）を検出する。
  static final RegExp _leadingNumberBadge = RegExp('^[0-9]️⃣[ 　]*');

  @override
  Widget build(BuildContext context) {
    if (line.header) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          line.text,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: foreground,
          ),
        ),
      );
    }

    final style = TextStyle(fontSize: 14, height: 1.6, color: foreground);

    // 連番バッジは固定幅の先頭列としてRowで切り出し、説明文はExpandedで
    // 折り返す（2行目以降もバッジ直後の位置で揃う）。アイコンは文中に
    // WidgetSpanで埋め込み、折り返しが左端へ戻るようにする。
    final badgeMatch = _leadingNumberBadge.matchAsPrefix(line.text);
    final badge = badgeMatch?.group(0)?.trimRight();
    final rest = badgeMatch == null
        ? line.text
        : line.text.substring(badgeMatch.end);

    final children = <Widget>[
      if (badge != null) ...[
        Text(badge, style: style),
        const SizedBox(width: 6),
      ],
    ];

    if (line.icon == null) {
      children.add(Expanded(child: Text(rest, style: style)));
    } else {
      // アイコンを文中のWidgetSpanとして描画する。Rowでアイコン列を切り出すと
      // 折り返し2行目がアイコン幅ぶん字下げされ、文末1文字だけが右に浮く
      // （例: 「…AI診 / 断」）。インラインなら2行目は左端へ戻る。
      final parts = rest.split('{{icon}}');
      final before = parts.first;
      final after = parts.length > 1 ? parts.sublist(1).join('{{icon}}') : '';
      children.add(
        Expanded(
          child: Text.rich(
            TextSpan(
              style: style,
              children: [
                if (before.isNotEmpty) TextSpan(text: before),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Icon(line.icon, size: 18, color: foreground),
                  ),
                ),
                if (after.isNotEmpty) TextSpan(text: after),
              ],
            ),
          ),
        ),
      );
    }

    final body = badge == null && line.icon == null
        ? Text(line.text, style: style)
        : Row(crossAxisAlignment: CrossAxisAlignment.start, children: children);

    return Padding(
      padding: EdgeInsets.only(left: line.indent ? 24 : 0, bottom: 6),
      child: body,
    );
  }
}
