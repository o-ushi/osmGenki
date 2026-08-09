import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// スコア内訳ダイアログなどで使う、ラベル＋値の1行。
class MetricRow extends StatelessWidget {
  const MetricRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.current;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: palette.textOnCardSecondary,
                fontSize: 14,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: palette.textOnCardPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
