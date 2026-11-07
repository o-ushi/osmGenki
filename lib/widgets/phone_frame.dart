import 'package:flutter/material.dart';

/// iPad など大きな画面で、アプリを iPhone の高さ（[phoneHeight]）のキャンバスに描き、
/// 画面いっぱいに拡大して表示する（iPad の iPhone 互換表示の「2x」相当）。
///
/// iPad 対応で公開済みのため iPhone 専用には戻せないので、アプリ側で再現する。
/// キャンバスの幅は画面の縦横比に合わせるので、余白なしで全画面に広がる
/// （13インチ iPad の縦向きで約 699×932pt を約 1.48 倍）。
/// スマホ（短辺 < [_tabletShortestSide]）では何もしない。
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});

  final Widget child;

  /// キャンバスの高さ（iPhone 16 Pro Max 相当の論理高さ）。
  static const phoneHeight = 932.0;

  // iPad の短辺は最小でも 744pt（iPad mini）。大きいスマホの横向きは 430pt 程度。
  static const _tabletShortestSide = 700.0;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screen = media.size;
    if (screen.shortestSide < _tabletShortestSide ||
        screen.height <= phoneHeight) {
      return child;
    }

    final scale = screen.height / phoneHeight;
    final canvas = Size(screen.width / scale, phoneHeight);

    // 安全領域・キーボードなどはキャンバス座標に縮めて渡す。
    // 画素密度は拡大分だけ上げ、画像がぼやけないようにする。
    final scaled = media.copyWith(
      size: canvas,
      devicePixelRatio: media.devicePixelRatio * scale,
      padding: media.padding / scale,
      viewPadding: media.viewPadding / scale,
      viewInsets: media.viewInsets / scale,
      systemGestureInsets: media.systemGestureInsets / scale,
    );

    return FittedBox(
      fit: BoxFit.fill,
      alignment: Alignment.topLeft,
      child: SizedBox.fromSize(
        size: canvas,
        child: MediaQuery(data: scaled, child: child),
      ),
    );
  }
}
