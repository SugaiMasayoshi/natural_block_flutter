import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

import '../rendered_spans.dart';

void main() {
  const theme = NaturalBlockTheme();

  /// A single-line cell, the shape the parser produces.
  TableCellNode cell(String text) => TableCellNode(
    children: [
      TextNode(children: [TextSpanNode(text: text)]),
    ],
  );

  /// A fixed ambient font size, so measured geometry is about layout rather
  /// than about whatever size the test harness happens to default to.
  Widget wrap(Widget child) => MaterialApp(
    home: DefaultTextStyle(
      style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
      child: child,
    ),
  );

  double leftOf(WidgetTester tester, String text) => tester
      .getRect(
        find.byWidget(
          tester
              .widgetList<RichText>(find.byType(RichText))
              .firstWhere((w) => w.text.toPlainText() == text),
        ),
      )
      .left;

  group('column widths', () {
    testWidgets('columns fit their content and agree across rows', (
      tester,
    ) async {
      // The reason tables are declared separately from plain rows: a
      // TableNode holds every row, so its columns can be sized to their
      // content and still line up. A RowNodeView cannot do this -- it
      // renders one row and cannot see its siblings.
      await tester.pumpWidget(
        wrap(const NaturalBlockView(source: '~Item^Price|Apple^200|Banana^1~')),
      );

      expect(find.byType(Table), findsOneWidget);

      final firstColumn = [
        'Item',
        'Apple',
        'Banana',
      ].map((t) => leftOf(tester, t));
      final secondColumn = ['Price', '200', '1'].map((t) => leftOf(tester, t));

      expect(
        firstColumn.toSet(),
        hasLength(1),
        reason: 'every first-column cell starts at the same x',
      );
      expect(
        secondColumn.toSet(),
        hasLength(1),
        reason: 'every second-column cell starts at the same x',
      );
      expect(
        secondColumn.first,
        lessThan(200),
        reason: 'the second column follows the content, not half the width',
      );
    });

    testWidgets(
      'the same rows without the marker still split the width evenly',
      (tester) async {
        // Guards the pair of policies against being accidentally unified:
        // plain rows must keep dividing the available width, because that
        // is what makes `LEFT^^RIGHT` push RIGHT to the far edge.
        await tester.pumpWidget(
          wrap(const NaturalBlockView(source: 'Item^Price|Apple^200|')),
        );

        expect(find.byType(Table), findsNothing);
        expect(
          leftOf(tester, 'Price'),
          greaterThan(300),
          reason: 'a plain row gives each cell an equal share of the width',
        );
      },
    );
  });

  group('placement', () {
    testWidgets('the block that holds a table centers it', (tester) async {
      // A table has no alignment of its own; `|=` positions it like anything
      // else in the block. Meaningful only because the table is sized to its
      // content: a width-filling table would have nothing to be centered
      // within.
      await tester.pumpWidget(wrap(const NaturalBlockView(source: '|=~A^B~')));

      // Its own centre against the surface's, rather than "far enough from
      // the left edge" -- that would pass for `|>` just as well.
      expect(
        tester.getRect(find.byType(Table)).center.dx,
        closeTo(tester.getRect(find.byType(MaterialApp)).center.dx, 1),
      );
    });

    testWidgets('a table in an unbounded width renders without throwing', (
      tester,
    ) async {
      // The block positions it with an Align rather than a width-filling
      // box: adding a marker must never be able to stop a document
      // rendering.
      await tester.pumpWidget(
        wrap(
          const Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: NaturalBlockView(source: '|=~A^B|C^D~'),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(Table), findsOneWidget);
    });
  });

  group('theming', () {
    testWidgets('cell padding keeps neighbouring cells from touching', (
      tester,
    ) async {
      // Content-sized columns make this load-bearing rather than cosmetic.
      const padded = NaturalBlockTheme(
        tableCellPadding: EdgeInsets.symmetric(horizontal: 40),
      );
      await tester.pumpWidget(
        wrap(const NaturalBlockView(source: '~A^B|C^D~', theme: padded)),
      );

      expect(leftOf(tester, 'A'), 40);
    });

    testWidgets('the border comes from the theme and can be removed', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const NaturalBlockView(source: '~A^B|C^D~')),
      );
      final border = tester.widget<Table>(find.byType(Table)).border!;
      // A frame on every edge, not just rules between cells: a table is the
      // one construct with a declared beginning and end, so an outer box
      // states something the source actually says.
      for (final side in [
        border.top,
        border.bottom,
        border.left,
        border.right,
        border.horizontalInside,
        border.verticalInside,
      ]) {
        expect(side.style, BorderStyle.solid);
      }

      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: '~A^B|C^D~',
            theme: NaturalBlockTheme(tableBorder: TableBorder()),
          ),
        ),
      );
      // None is a value, not null: every side draws nothing.
      final unruled = tester.widget<Table>(find.byType(Table)).border!;
      expect(unruled.horizontalInside.style, BorderStyle.none);
      expect(unruled.verticalInside.style, BorderStyle.none);
      expect(unruled.top.style, BorderStyle.none);
    });

    testWidgets('striping is off by default and paints odd rows when set', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const NaturalBlockView(source: '~A^B|C^D~')),
      );
      expect(
        tester
            .widget<Table>(find.byType(Table))
            .children
            .every((r) => r.decoration == null),
        isTrue,
      );

      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: '~A^B|C^D~',
            theme: NaturalBlockTheme(tableStripe: Color(0xFFEEEEEE)),
          ),
        ),
      );
      final rows = tester.widget<Table>(find.byType(Table)).children;
      expect(rows[0].decoration, isNull, reason: 'the first row is unpainted');
      expect(rows[1].decoration, isNotNull);
    });
  });

  group('shapes a consumer can build by hand', () {
    // The parser guarantees every row has the same cell count, but
    // TableNodeView is exported, so a hand-built node can violate that.
    // These pin what happens rather than leaving it to be discovered.
    testWidgets('a one-row table renders and is never striped', (tester) async {
      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: '~only^row~',
            theme: NaturalBlockTheme(tableStripe: Color(0xFFEEEEEE)),
          ),
        ),
      );

      final table = tester.widget<Table>(find.byType(Table));
      expect(table.children, hasLength(1));
      expect(
        table.children.single.decoration,
        isNull,
        reason: 'banding starts at the second row, so one row is unpainted',
      );
    });

    testWidgets('a one-column table renders', (tester) async {
      // Not reachable from markup -- a block with no `^` never becomes a row
      // -- but constructible, so it should not fall over.
      await tester.pumpWidget(
        wrap(
          TableNodeView(
            node: TableNode(
              children: [
                TableRowNode(children: [cell('only')]),
              ],
            ),
            scope: NaturalBlockScope(
              theme: theme,
              registry: NaturalBlockRegistry.defaults,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(Table), findsOneWidget);
    });

    testWidgets('a ragged row is squared off to the table width', (
      tester,
    ) async {
      // Flutter's `Table` asserts unless every row holds the same number of
      // children. That is this layer's problem, not the tree's: the parser
      // records only the cells the author wrote, and the view pads.
      await tester.pumpWidget(
        wrap(
          TableNodeView(
            node: TableNode(
              children: [
                TableRowNode(children: [cell('a'), cell('b')]),
                TableRowNode(children: [cell('c')]),
              ],
            ),
            scope: NaturalBlockScope(
              theme: theme,
              registry: NaturalBlockRegistry.defaults,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final rows = tester.widget<Table>(find.byType(Table)).children;
      expect([for (final r in rows) r.children.length], [2, 2]);
    });

    testWidgets('a cell that stated nothing is drawn with its column', (
      tester,
    ) async {
      // The resolution the parser no longer does: the tree says the second
      // cell of row 2 stated nothing, and that the column stated `end`.
      const source = '~|A^>B\n|C^D\n~';
      final table =
          (NaturalBlockParser.parse(source).children.single as ColumnNode)
                  .children
                  .single
              as TableNode;

      expect(table.columns, [HorizontalAlign.unstated, HorizontalAlign.end]);
      expect(
        table.children[1].children[1].align,
        HorizontalAlign.unstated,
        reason: 'the source wrote no marker on that cell',
      );

      await tester.pumpWidget(wrap(const NaturalBlockView(source: source)));

      final aligned = tester.widgetList<ColumnNodeView>(
        find.byType(ColumnNodeView),
      );
      expect(
        aligned.where((v) => v.align == HorizontalAlign.end).length,
        2,
        reason: 'both cells of the end-aligned column are drawn end-aligned',
      );
    });
  });

  group('registry', () {
    testWidgets('cells are built through the registry', (tester) async {
      final registry = NaturalBlockRegistry(
        tableCell: (context, node, scope) => const Placeholder(),
      );

      await tester.pumpWidget(
        wrap(
          TableNodeView(
            node: TableNode(
              children: [
                TableRowNode(
                  children: [
                    TableCellNode(children: []),
                    TableCellNode(),
                  ],
                ),
              ],
            ),
            scope: NaturalBlockScope(theme: theme, registry: registry),
          ),
        ),
      );

      expect(find.byType(Placeholder), findsNWidgets(2));
    });

    testWidgets('an actionable span inside a table cell is tappable', (
      tester,
    ) async {
      final tapped = <String>[];
      await tester.pumpWidget(
        wrap(
          NaturalBlockView(
            source: '~:@tap:@^B|C^D~',
            actions: NaturalBlockActions(onTap: tapped.add),
          ),
        ),
      );

      final span = renderedSpans(tester).single;
      expect(span.text, 'tap');
      (span.recognizer! as TapGestureRecognizer).onTap!();

      expect(tapped, ['tap']);
    });
  });
}
