// Smoke tests for the natural_block_flutter example app. The app exists to
// show every feature working, so these check that it actually does -- a
// sample that stopped rendering would otherwise be invisible until someone
// scrolled to it by hand.

import 'package:example/main.dart';
import 'package:flutter/material.dart';
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

  testWidgets('everything is inside a SelectionArea so text is selectable', (
    tester,
  ) async {
    // TextNodeView is built with Text.rich specifically so this works; the
    // app wraps its content to demonstrate it.
    await tester.pumpWidget(const MyApp());

    expect(find.byType(SelectionArea), findsOneWidget);
  });

  testWidgets('the registry demo really substitutes a widget', (tester) async {
    // The same source is rendered twice, once with a builder registered for
    // TextNode. Chips are what that builder produces.
    await tester.pumpWidget(const MyApp());

    expect(find.byType(Chip), findsWidgets);
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
