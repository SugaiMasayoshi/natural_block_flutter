import 'package:example/custom_runs.dart';
import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

void main() {
  testWidgets('the app launches, and both theme toggles draw without error', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('試してみよう'), findsOneWidget);
    expect(find.bySubtype<NaturalBlockView>(), findsWidgets);

    await tester.tap(find.byType(Switch).last); // dark
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch).first); // striped
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('a quiz choice says whether it was right once tapped', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: NaturalBlockView(
            source: 'Q\n:@wrong(A→no):@ :@correct(B→yes):@',
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
}
