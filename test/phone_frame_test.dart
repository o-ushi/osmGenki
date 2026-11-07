import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:osm_genki/widgets/phone_frame.dart';

void main() {
  Future<(Size, Rect)> pumpFrame(WidgetTester tester, Size screen) async {
    tester.view.physicalSize = screen;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late Size seen;
    const key = ValueKey('content');
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => PhoneFrame(child: child!),
        home: Builder(
          builder: (context) {
            seen = MediaQuery.sizeOf(context);
            return const SizedBox.expand(key: key);
          },
        ),
      ),
    );
    return (seen, tester.getRect(find.byKey(key)));
  }

  testWidgets('iPad では iPhone の高さのキャンバスを画面いっぱいに拡大する', (tester) async {
    final (size, rect) = await pumpFrame(tester, const Size(1032, 1376));
    expect(size.height, PhoneFrame.phoneHeight);
    expect(size.width, closeTo(1032 / (1376 / 932), 0.01));
    // 拡大後は画面全体を覆う（余白なし）。
    expect(rect.left, closeTo(0, 0.01));
    expect(rect.top, closeTo(0, 0.01));
    expect(rect.width, closeTo(1032, 0.01));
    expect(rect.height, closeTo(1376, 0.01));
  });

  testWidgets('iPhone サイズでは何もしない', (tester) async {
    final (size, _) = await pumpFrame(tester, const Size(390, 844));
    expect(size, const Size(390, 844));
  });
}
