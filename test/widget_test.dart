import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wearther_app/main.dart'; // 실제 경로로 변경

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // 위젯을 테스트 트리에 추가합니다.
    await tester.pumpWidget(MyApp());

    // '0' 텍스트가 처음에 보여야 합니다.
    expect(find.text('0'), findsOneWidget);

    // '+' 버튼을 탭합니다.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump(); // 상태 업데이트를 위해 pump합니다.

    // '1' 텍스트가 보여야 합니다.
    expect(find.text('1'), findsOneWidget);
  });
}
