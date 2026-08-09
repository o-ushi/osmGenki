import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:osm_genki/widgets/swipe_down_to_dismiss.dart';

void main() {
  Future<void> pushDismissible(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Center(child: Text('Home')))),
    );
    final context = tester.element(find.text('Home'));
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SwipeDownToDismiss(
          child: Container(color: Colors.white, width: 400, height: 800),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('素早い右方向のフリックでポップされる（左端からの右スワイプ）', (
    WidgetTester tester,
  ) async {
    await pushDismissible(tester);

    // SwipeToCloseWrapper は左端スタートの右スワイプのみ閉じる。
    final gesture = await tester.startGesture(const Offset(16, 400));
    await gesture.moveBy(
      const Offset(40, 0),
      timeStamp: const Duration(milliseconds: 10),
    );
    await gesture.moveBy(
      const Offset(80, 0),
      timeStamp: const Duration(milliseconds: 20),
    );
    await gesture.moveBy(
      const Offset(120, 0),
      timeStamp: const Duration(milliseconds: 30),
    );
    await gesture.up(timeStamp: const Duration(milliseconds: 30));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('素早い下方向のフリックでポップされる（下スワイプでの本来の動作）', (
    WidgetTester tester,
  ) async {
    await pushDismissible(tester);

    await tester.fling(find.byType(Container), const Offset(0, 300), 2000);
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });

  // 右手親指で長く上スクロールする際、親指の付け根を軸にした弧を描く動きに
  // なりがちで、序盤のごくわずかな段階でたまたま右方向へドリフトすることがある。
  // SwipeToCloseWrapper は右スワイプを左端スタートに限定するため、
  // 中央からの上スクロール＋右ドリフトでは閉じない。
  testWidgets(
    '上スクロールの序盤にわずかな右ドリフトがあっても、'
    '全体としては上方向が支配的ならポップされない（回帰テスト）',
    (WidgetTester tester) async {
      await pushDismissible(tester);

      final gesture = await tester.startGesture(const Offset(200, 500));
      await gesture.moveTo(
        const Offset(203, 300),
        timeStamp: const Duration(milliseconds: 40),
      );
      await gesture.moveTo(
        const Offset(214, 250),
        timeStamp: const Duration(milliseconds: 80),
      );
      await gesture.moveTo(
        const Offset(216, 150),
        timeStamp: const Duration(milliseconds: 120),
      );
      await gesture.moveTo(
        const Offset(300, 148),
        timeStamp: const Duration(milliseconds: 130),
      );
      await gesture.up(timeStamp: const Duration(milliseconds: 130));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsNothing);
    },
  );
}
