import 'package:flutter_test/flutter_test.dart';
import 'package:recify/main.dart';

void main() {
  testWidgets('Recify app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RecifyApp());
    expect(find.byType(RecifyApp), findsOneWidget);
  });
}
