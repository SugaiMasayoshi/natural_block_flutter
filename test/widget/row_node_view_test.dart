import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

void main() {
  group('RowNodeView', () {
    testWidgets(
      'gives one RowNode one Expanded cell, stacking its own lines vertically',
      (tester) async {
        // A single RowNode is a single *cell*; its children are the lines
        // inside that cell, so they must stack -- not become sibling cells.
        final node = RowNode(
          children: [
            TextNode(children: [TextSpanNode(text: 'a')]),
            TextSpanNode(text: 'x'), // non-TextNode child: filtered out
            TextNode(children: [TextSpanNode(text: 'b')]),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: RowNodeView(nodes: [node], theme: const NaturalBlockTheme()),
          ),
        );

        expect(find.byType(Row), findsOneWidget);
        expect(find.byType(Expanded), findsOneWidget);
        expect(find.byType(TextNodeView), findsNWidgets(2));

        // The two lines are stacked inside the one cell.
        final column = tester.widget<Column>(
          find.descendant(
            of: find.byType(Expanded),
            matching: find.byType(Column),
          ),
        );
        expect(column.children, hasLength(2));
      },
    );

    testWidgets('a single-line cell needs no Column wrapper', (tester) async {
      final node = RowNode(
        children: [
          TextNode(children: [TextSpanNode(text: 'only')]),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RowNodeView(nodes: [node], theme: const NaturalBlockTheme()),
        ),
      );

      expect(find.byType(Expanded), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(Expanded),
          matching: find.byType(Column),
        ),
        findsNothing,
      );
    });

    testWidgets('merges multiple RowNodes into one Row, one cell each', (
      tester,
    ) async {
      final nodes = [
        RowNode(children: [TextNode(children: [TextSpanNode(text: 'left')])]),
        RowNode(children: [TextNode(children: [TextSpanNode(text: 'right')])]),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: RowNodeView(nodes: nodes, theme: const NaturalBlockTheme()),
        ),
      );

      expect(find.byType(Row), findsOneWidget);
      expect(find.byType(Expanded), findsNWidgets(2));
    });

    testWidgets('an empty nodes list renders an empty Row without throwing', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RowNodeView(nodes: const [], theme: const NaturalBlockTheme()),
        ),
      );

      final row = tester.widget<Row>(find.byType(Row));
      expect(row.children, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });
}
