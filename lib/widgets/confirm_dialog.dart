import 'package:flutter/material.dart';

/// 確認ダイアログの共通ヘルパー。削除・初期化・会話リセットなどで使う。
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  Color? confirmColor,
  String? cancelLabel,
  bool barrierDismissible = false,
}) async {
  final localizations = MaterialLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(cancelLabel ?? localizations.cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: confirmColor == null
              ? null
              : TextButton.styleFrom(foregroundColor: confirmColor),
          child: Text(confirmLabel ?? localizations.okButtonLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
