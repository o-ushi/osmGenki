import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// 左スワイプで削除するときに、カードの下から現れる赤い背景。
/// 日記一覧・診断結果一覧で共通に使う。
class DeleteSwipeBackground extends StatelessWidget {
  const DeleteSwipeBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: kRecordingColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(Icons.delete_rounded, color: AppColors.current.onAccent),
    );
  }
}
