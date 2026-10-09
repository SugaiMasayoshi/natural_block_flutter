import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

void main() {
  group('RowNodeView', () {
    testWidgets('gives every cell one Expanded, empty ones included, and '
        'stacks a multi-line cell instead of splitting it', (tester) async {
      // The split is the regression this guards: RowNodeView used to flatten
      // every RowNode's children into the Row, so a two-line left cell
      // rendered as two cells side by side. An empty cell still takes its
      // share of the width, which is what keeps later columns lined up.
      TextNode line(String s) => TextNode(children: [TextSpanNode(text: s)]);

      await tester.pumpWidget(
        MaterialApp(
          home: RowNodeView(
            node: RowNode(
              children: [
                ColumnNode(children: [line('a'), line('b')]),
                ColumnNode(children: []),
                ColumnNode(children: [line('c')]),
              ],
            ),
            scope: const NaturalBlockScope(),
          ),
        ),
      );

      expect(find.byType(Row), findsOneWidget);
      expect(find.byType(Expanded), findsNWidgets(3));
      expect(find.byType(TextNodeView), findsNWidgets(3));
      expect(tester.takeException(), isNull);

      final first = tester.widget<Column>(
        find.descendant(
          of: find.byType(Expanded).first,
          matching: find.byType(Column),
        ),
      );
      expect(first.children, hasLength(2), reason: 'two lines, one cell');
    });
  });
}
