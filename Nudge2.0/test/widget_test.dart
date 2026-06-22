// This is a basic Flutter widget test for Nudge 2.0.
import 'package:flutter_test/flutter_test.dart';
import 'package:nudge_2/main.dart';

void main() {
  testWidgets('Nudge 2.0 smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NudgeApp());

    // Verify our initial app layout loads up the transport selectors successfully.
    expect(find.text('How are you\ntravelling?'), findsOneWidget);
  });
}