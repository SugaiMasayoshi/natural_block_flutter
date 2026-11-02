// Smoke tests for the natural_block_flutter example app. The app exists to
// show every feature working, so these check that it actually does -- a
// sample that stopped rendering would otherwise be invisible until someone
// scrolled to it by hand.

import 'package:example/custom_runs.dart';
import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

void main() {
  testWidgets('the app launches with the playground and the samples', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('natural_block_flutter example'), findsOneWidget);
    expect(find.text('試してみよう'), findsOneWidget);
    expect(find.byType(NaturalBlockView), findsWidgets);
  });

  testWidgets('every rendered document is selectable, and the input is not', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    for (final view in find.byType(NaturalBlockView).evaluate()) {
      expect(
        find.ancestor(
          of: find.byWidget(view.widget),
          matching: find.byType(SelectionArea),
        ),
        findsOneWidget,
      );
    }
    expect(
      find.ancestor(
        of: find.byType(TextField),
        matching: find.byType(SelectionArea),
      ),
      findsNothing,
      reason: 'a SelectionArea takes the up and down arrows from the input',
    );
  });

  testWidgets('a quiz choice says whether it was right once tapped', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NaturalBlockView(
            source: 'Q\n:@wrong(A → no):@ :@correct(B → yes):@',
            customs: appCustoms,
          ),
        ),
      ),
    );

    expect(find.text('A'), findsOneWidget);
    expect(find.text('no'), findsNothing);
    expect(find.byIcon(Icons.close), findsNothing);

    await tester.tap(find.text('A'));
    await tester.pump();
    expect(find.text('no'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.text('yes'), findsNothing, reason: 'only the tapped choice');

    await tester.tap(find.text('B'));
    await tester.pump();
    expect(find.text('yes'), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);

    await tester.tap(find.text('A'));
    await tester.pump();
    expect(find.text('no'), findsNothing, reason: 'a second tap closes it');
    expect(find.byIcon(Icons.close), findsNothing);
  });

  testWidgets('the up arrow moves the cursor in the playground', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.tap(find.byType(TextField));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    final end = field.controller!.text.length;
    field.controller!.selection = TextSelection.collapsed(offset: end);
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();

    expect(field.controller!.selection.baseOffset, lessThan(end));
  });

  testWidgets('both theme toggles work and nothing throws', (tester) async {
    // The theme comes from the app's own ColorScheme, so brightness and
    // striping change what NaturalBlockView renders rather than only the
    // Material chrome around it.
    await tester.pumpWidget(const MyApp());
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(Switch).last); // dark
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byType(Switch).first); // striped
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.byType(NaturalBlockView), findsWidgets);
  });
}
