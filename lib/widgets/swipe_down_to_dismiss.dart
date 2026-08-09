import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'swipe_to_close_wrapper.dart';

Route<T> fullscreenDismissRoute<T>({required WidgetBuilder builder}) {
  return switch (defaultTargetPlatform) {
    TargetPlatform.iOS || TargetPlatform.macOS => CupertinoPageRoute<T>(
      fullscreenDialog: true,
      builder: builder,
    ),
    _ => MaterialPageRoute<T>(fullscreenDialog: true, builder: builder),
  };
}

/// [SwipeToCloseWrapper]への薄い互換ラッパー（下/右スワイプで閉じる）。
/// [scrollController]は互換のため受け取るが無視する。
class SwipeDownToDismiss extends StatelessWidget {
  const SwipeDownToDismiss({
    super.key,
    required this.child,
    this.scrollController,
    this.onClose,
  });

  final Widget child;
  final ScrollController? scrollController;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return SwipeToCloseWrapper(onClose: onClose, child: child);
  }
}
