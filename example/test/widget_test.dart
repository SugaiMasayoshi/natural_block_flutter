// A basic smoke test for the natural_block_flutter example app: it should
// launch to the demo page, show the playground, and render every sample.

import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

void main() {
  testWidgets('demo app launches and renders the playground and samples', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    // The app bar and the live-editing playground are both present.
    expect(find.text('natural_block_flutter example'), findsOneWidget);
    expect(find.text('試してみよう'), findsOneWidget);

    // Every sample source string is rendered by a NaturalBlockView.
    expect(find.byType(NaturalBlockView), findsWidgets);
  });
}
