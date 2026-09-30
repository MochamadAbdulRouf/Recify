import 'package:flutter_test/flutter_test.dart';
import 'package:recify/main.dart';
import 'package:recify/presentation/providers/theme_provider.dart';

void main() {
  testWidgets('Recify app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(RecifyApp(themeProvider: ThemeProvider()));
    expect(find.byType(RecifyApp), findsOneWidget);
  });
}
