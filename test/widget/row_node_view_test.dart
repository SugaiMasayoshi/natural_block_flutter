import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

void main() {
  group('RowNodeView', () {
    testWidgets('gives every cell one Expanded, empty ones included', (
      tester,
    ) async {
      // An empty cell still takes its share of the width, which is what
      // keeps later columns lined up between rows.
      await tester.pumpWidget(
        const MaterialApp(
          home: RowNodeView(cells: [Text('a'), SizedBox.shrink(), Text('c')]),
        ),
      );

      expect(find.byType(Row), findsOneWidget);
      expect(find.byType(Expanded), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('shrink-wraps its cells where the width is unbounded', (
      tester,
    ) async {
      // A Row cannot lay out flex children when its own width is unbounded,
      // so wrapping every cell in Expanded unconditionally made any document
      // containing `^` throw inside a horizontal scroll view.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: RowNodeView(cells: [Text('a'), Text('b')]),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(Expanded), findsNothing);
    });
  });
}
