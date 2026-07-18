import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vakil_ai/app.dart';

void main() {
  testWidgets('App boots to the splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: VakilAiApp()));
    expect(find.text('Vakil AI'), findsWidgets);
    // Splash auto-navigates after a delay; let that timer fire before teardown.
    await tester.pump(const Duration(seconds: 2));
  });
}
