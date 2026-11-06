import 'package:flutter_test/flutter_test.dart';
import 'package:elyxia_eb/main.dart';

void main() {
  testWidgets('ElyxiaEbApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ElyxiaEbApp());
    expect(find.byType(ElyxiaEbApp), findsOneWidget);
  });
}
