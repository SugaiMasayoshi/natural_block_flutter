import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

void main() {
  const theme = NaturalBlockTheme();

  Future<List<Widget>> buildWith(
    WidgetTester tester,
    NaturalBlockBuilders builders,
    List<Widget> Function(BuildContext context, NaturalBlockScope scope) build,
  ) async {
    late List<Widget> built;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            built = build(
              context,
              NaturalBlockScope(theme: theme, builders: builders),
            );
            return Column(children: built);
          },
        ),
      ),
    );
    return built;
  }

  /// The blocks and rows a document holds.
  Future<List<Widget>> pumpLayouts(
    WidgetTester tester,
    NaturalBlockBuilders builders,
    List<LayoutNode> nodes,
  ) => buildWith(tester, builders, (c, scope) => buildLayouts(c, nodes, scope));

  /// The lines, raw blocks and tables a block holds.
  Future<List<Widget>> pumpContents(
    WidgetTester tester,
    NaturalBlockBuilders builders,
    List<ContentNode> nodes,
  ) =>
      buildWith(tester, builders, (c, scope) => buildContents(c, nodes, scope));

  TextNode text(String s) => TextNode(children: [TextSpanNode(text: s)]);

  group('NaturalBlockBuilders.defaults', () {
    testWidgets('a document\'s blocks and rows go to their views', (
      tester,
    ) async {
      await pumpLayouts(tester, NaturalBlockBuilders.defaults, [
        RowNode(
          children: [
            ColumnNode(children: [text('a')]),
            ColumnNode(children: [text('b')]),
          ],
        ),
        ColumnNode(children: [text('c')]),
      ]);

      expect(find.byType(RowNodeView), findsOneWidget);
      // One direct ColumnNode, and one for each of the RowNode's two cells.
      expect(find.byType(ColumnNodeView), findsNWidgets(3));
      expect(find.byType(TextNodeView), findsNWidgets(3));
    });

    testWidgets('a block\'s contents go to their views', (tester) async {
      await pumpContents(tester, NaturalBlockBuilders.defaults, [
        text('line'),
        RawNode(text: 'code'),
        TableNode(
          children: [
            TableRowNode(
              children: [
                TableCellNode(children: [text('cell')]),
              ],
            ),
          ],
        ),
      ]);

      expect(find.byType(TextNodeView), findsNWidgets(2)); // the line, and
      expect(find.byType(RawNodeView), findsOneWidget); // the table's cell
      expect(find.byType(TableNodeView), findsOneWidget);
    });

    testWidgets(
      'one RowNode renders as one Row, keeping other blocks separate',
      (tester) async {
        final built = await pumpLayouts(tester, NaturalBlockBuilders.defaults, [
          RowNode(
            children: [
              ColumnNode(children: [text('a')]),
              ColumnNode(children: [text('b')]),
            ],
          ),
          ColumnNode(children: [text('between')]),
          RowNode(
            children: [
              ColumnNode(children: [text('c')]),
              ColumnNode(children: [text('d')]),
            ],
          ),
        ]);

        // 2 RowNodes + 1 plain block = 3 top-level widgets.
        expect(built.length, 3);
        expect(find.byType(RowNodeView), findsNWidgets(2));
        expect(find.byType(Row), findsNWidgets(2));
        expect(
          find.byType(Expanded),
          findsNWidgets(4),
        ); // a+b in one Row, c+d in the other
      },
    );
  });

  group('builders of your own', () {
    testWidgets('one replaces the default for that kind of node', (
      tester,
    ) async {
      final builders = NaturalBlockBuilders(
        text: (context, node, scope) => const Placeholder(),
      );

      await pumpContents(tester, builders, [text('a')]);

      expect(find.byType(Placeholder), findsOneWidget);
      expect(find.byType(TextNodeView), findsNothing);
    });

    testWidgets(
      'a ColumnNode builder also applies to row cells, since cells are '
      'built through the builders',
      (tester) async {
        final builders = NaturalBlockBuilders(
          column: (context, node, scope) => const Placeholder(),
        );

        await pumpLayouts(tester, builders, [
          RowNode(
            children: [
              ColumnNode(children: [text('a')]),
              ColumnNode(children: [text('b')]),
            ],
          ),
        ]);

        expect(find.byType(Placeholder), findsNWidgets(2));
        expect(find.byType(TextNodeView), findsNothing);
      },
    );

    testWidgets('the kinds left out keep their default', (tester) async {
      final builders = NaturalBlockBuilders(
        text: (context, node, scope) => const Placeholder(),
      );

      await pumpLayouts(tester, builders, [
        ColumnNode(children: [text('a')]),
      ]);

      expect(find.byType(ColumnNodeView), findsOneWidget);
      expect(find.byType(Placeholder), findsOneWidget);
    });
  });
}
