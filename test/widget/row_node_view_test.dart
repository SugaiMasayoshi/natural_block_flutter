import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

void main() {
  const theme = NaturalBlockTheme();
  const registry = NaturalBlockRegistry.defaults;

  group('RowNodeView', () {
    testWidgets(
      'gives each cell (ColumnNode) one Expanded, stacking a multi-line '
      "cell's lines vertically",
      (tester) async {
        final node = RowNode(
          children: [
            ColumnNode(
              children: [
                TextNode(children: [TextSpanNode(text: 'a')]),
                TextNode(children: [TextSpanNode(text: 'b')]),
              ],
            ),
            ColumnNode(
              children: [
                TextNode(children: [TextSpanNode(text: 'c')]),
              ],
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: RowNodeView(
              node: node,
              scope: NaturalBlockScope(theme: theme, registry: registry),
            ),
          ),
        );

        expect(find.byType(Row), findsOneWidget);
        expect(find.byType(Expanded), findsNWidgets(2));
        expect(find.byType(TextNodeView), findsNWidgets(3));

        // The two lines of the first cell are stacked.
        final column = tester.widget<Column>(
          find.descendant(
            of: find.byType(Expanded).first,
            matching: find.byType(Column),
          ),
        );
        expect(column.children, hasLength(2));
      },
    );

    testWidgets('renders one Expanded cell per ColumnNode child', (
      tester,
    ) async {
      final node = RowNode(
        children: [
          ColumnNode(
            children: [
              TextNode(children: [TextSpanNode(text: 'left')]),
            ],
          ),
          ColumnNode(
            children: [
              TextNode(children: [TextSpanNode(text: 'right')]),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RowNodeView(
            node: node,
            scope: NaturalBlockScope(theme: theme, registry: registry),
          ),
        ),
      );

      expect(find.byType(Row), findsOneWidget);
      expect(find.byType(Expanded), findsNWidgets(2));
    });

    testWidgets('an empty cell renders as an empty Expanded', (tester) async {
      final node = RowNode(
        children: [
          ColumnNode(
            children: [
              TextNode(children: [TextSpanNode(text: 'left')]),
            ],
          ),
          ColumnNode(children: []), // middle cell deliberately blank
          ColumnNode(
            children: [
              TextNode(children: [TextSpanNode(text: 'right')]),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RowNodeView(
            node: node,
            scope: NaturalBlockScope(theme: theme, registry: registry),
          ),
        ),
      );

      expect(find.byType(Expanded), findsNWidgets(3));
      expect(find.byType(TextNodeView), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'cells are built through the registry, so a custom builder applies '
      'to row cells too',
      (tester) async {
        final customRegistry = NaturalBlockRegistry(
          column: (context, node, scope) => const Placeholder(),
        );
        final node = RowNode(children: [ColumnNode(), ColumnNode()]);

        await tester.pumpWidget(
          MaterialApp(
            home: RowNodeView(
              node: node,
              scope: NaturalBlockScope(theme: theme, registry: customRegistry),
            ),
          ),
        );

        expect(find.byType(Placeholder), findsNWidgets(2));
        expect(find.byType(ColumnNodeView), findsNothing);
      },
    );
  });
}
