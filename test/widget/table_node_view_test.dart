// 【解説】[テスト16/21] 表の描画。RowNodeView との違いは幅の決め方だけ。
// 【解説】
// 【解説】 最初の group が本質で、列が内容の幅になり、かつ行をまたいで
// 【解説】 一致すること。普通の行は幅を等分するので、ここが唯一の違い。
// 【解説】
// 【解説】 罫線と縞は装飾構文では書けないのでテーマが持つ。既定が外枠まで
// 【解説】 引くのは、表がこの言語で唯一「始まりと終わりを宣言する」構文で、
// 【解説】 枠がソースの言っていることを表すから。
// 【解説】
// 【解説】 "shapes a consumer can build by hand" は、パーサからは出てこない
// 【解説】 が利用側が手で組める形。1行だけの表、1列だけの表、そして列数が
// 【解説】 揃わない表は「間違って描くより目立って落ちる」ことを固定している。
// 【解説】 次: test/widget/natural_block_theme_test.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

import '../rendered_spans.dart';

void main() {
  const theme = NaturalBlockTheme();

  /// A single-line cell, the shape the parser produces.
  ColumnNode cell(String text) => ColumnNode(
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
        wrap(
          const NaturalBlockView(source: '~Item^Price|Apple^200|Banana^1~'),
        ),
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
    testWidgets('`~=` centers the table', (tester) async {
      // Meaningful only because the table is sized to its content: a
      // width-filling table would have nothing to be centered within.
      await tester.pumpWidget(wrap(const NaturalBlockView(source: '~=A^B~')));

      final a = tester.getRect(
        find.byWidget(tester.widget<RichText>(find.byType(RichText).first)),
      );
      expect(a.left, greaterThan(300));
    });

    testWidgets('a table in an unbounded width renders without throwing', (
      tester,
    ) async {
      // Align rather than a width-filling box, for the same reason
      // ColumnNodeView uses one: adding a marker must never be able to stop
      // a document rendering.
      await tester.pumpWidget(
        wrap(
          const Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: NaturalBlockView(source: '~=A^B|C^D~'),
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
            theme: NaturalBlockTheme(tableBorder: null),
          ),
        ),
      );
      expect(tester.widget<Table>(find.byType(Table)).border, isNull);
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
                RowNode(children: [cell('only')]),
              ],
            ),
            theme: theme,
            registry: NaturalBlockRegistry.defaults,
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
                RowNode(children: [cell('a'), cell('b')]),
                RowNode(children: [cell('c')]),
              ],
            ),
            theme: theme,
            registry: NaturalBlockRegistry.defaults,
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
          NaturalBlockParser.parse(source).children.single as TableNode;

      expect(table.columns, [null, BlockAlign.end]);
      expect(
        table.children[1].children[1].align,
        isNull,
        reason: 'the source wrote no marker on that cell',
      );

      await tester.pumpWidget(wrap(const NaturalBlockView(source: source)));

      final aligned = tester.widgetList<ColumnNodeView>(
        find.byType(ColumnNodeView),
      );
      expect(
        aligned.where((v) => v.align == BlockAlign.end).length,
        2,
        reason: 'both cells of the end-aligned column are drawn end-aligned',
      );
    });
  });

  group('registry', () {
    testWidgets('cells are built through the registry', (tester) async {
      final registry = NaturalBlockRegistry.defaults.register(
        ColumnNode,
        (context, node, theme, registry, onActionTap) => const Placeholder(),
      );

      await tester.pumpWidget(
        wrap(
          TableNodeView(
            node: TableNode(
              children: [
                RowNode(
                  children: [
                    ColumnNode(children: []),
                    ColumnNode(),
                  ],
                ),
              ],
            ),
            theme: theme,
            registry: registry,
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
          NaturalBlockView(source: '~:@tap:@^B|C^D~', onActionTap: tapped.add),
        ),
      );

      final span = renderedSpans(tester).single;
      expect(span.text, 'tap');
      (span.recognizer! as TapGestureRecognizer).onTap!();

      expect(tapped, ['tap']);
    });
  });
}
