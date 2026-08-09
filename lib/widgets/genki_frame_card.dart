import 'package:flutter/material.dart';

import '../models/appearance_models.dart';

/// osmWashabeの `WashabeFrameCard` をそのまま移植したカード意匠。
/// クリーム地＋縁＋左のアクセントストライプが「washabeらしさ」の核。
/// [style] は `AppAppearance.resolvedFrameStyle()` の結果を渡す。
class GenkiFrameCard extends StatelessWidget {
  const GenkiFrameCard({
    super.key,
    required this.style,
    required this.child,
    this.padding,
  });

  final FrameResolvedStyle style;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: style.usesLightText ? ThemeData.dark() : ThemeData.light(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: style.cardFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: style.cardBorder, width: style.borderWidth),
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Positioned(
              left: 8,
              top: 12,
              bottom: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: style.accentStrip,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const SizedBox(width: 4),
              ),
            ),
            Padding(
              padding: padding ?? const EdgeInsets.fromLTRB(20, 14, 14, 14),
              child: DefaultTextStyle.merge(
                style: TextStyle(color: style.readablePrimaryText),
                child: IconTheme.merge(
                  data: IconThemeData(color: style.readablePrimaryText),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
