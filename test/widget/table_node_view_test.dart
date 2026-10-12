import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

import '../rendered_spans.dart';

void main() {
  TableCellNode cell(String text) => TableCellNode(
    children: [
      TextNode(children: [TextSpanNode(text: text)]),
    ],
  );

  Widget wrap(Widget child) => MaterialApp(
    home: DefaultTextStyle(
      style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
      child: child,
    ),
  );

  Future<void> pump(
    WidgetTester tester,
    String source, {
    NaturalBlockTheme theme = const NaturalBlockTheme(),
  }) => tester.pumpWidget(wrap(NaturalBlockView(source: source, theme: theme)));

  Table tableOf(WidgetTester tester) =>
      tester.widget<Table>(find.byType(Table));

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
      await pump(tester, '~Item^Price|Apple^200|Banana^1~');

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
        await pump(tester, 'Item^Price|Apple^200|');

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
      await pump(tester, '|=~A^B~');

      expect(
        tester.getRect(find.byType(Table)).center.dx,
        closeTo(tester.getRect(find.byType(MaterialApp)).center.dx, 1),
      );
    });
  });

  group('theming', () {
    testWidgets('cell padding keeps neighbouring cells from touching', (
      tester,
    ) async {
      const padded = NaturalBlockTheme(
        tableCellPadding: EdgeInsets.symmetric(horizontal: 40),
      );
      await pump(tester, '~A^B|C^D~', theme: padded);

      expect(leftOf(tester, 'A'), 40);
    });

    testWidgets('the border comes from the theme and can be removed', (
      tester,
    ) async {
      await pump(tester, '~A^B|C^D~');
      final border = tableOf(tester).border!;
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

      await pump(
        tester,
        '~A^B|C^D~',
        theme: const NaturalBlockTheme(tableBorder: TableBorder()),
      );
      final unruled = tableOf(tester).border!;
      expect(unruled.horizontalInside.style, BorderStyle.none);
      expect(unruled.verticalInside.style, BorderStyle.none);
      expect(unruled.top.style, BorderStyle.none);
    });

    testWidgets('striping is off by default and paints odd rows when set', (
      tester,
    ) async {
      await pump(tester, '~A^B|C^D~');
      expect(
        tableOf(tester).children.every((r) => r.decoration == null),
        isTrue,
      );

      await pump(
        tester,
        '~A^B|C^D~',
        theme: const NaturalBlockTheme(tableStripe: Color(0xFFEEEEEE)),
      );
      final rows = tableOf(tester).children;
      expect(rows[0].decoration, isNull, reason: 'the first row is unpainted');
      expect(rows[1].decoration, isNotNull);
    });
  });

  group('shapes a consumer can build by hand', () {
    testWidgets('a table of one row, or one column, still renders', (
      tester,
    ) async {
      await pump(
        tester,
        '~only^row~',
        theme: const NaturalBlockTheme(tableStripe: Color(0xFFEEEEEE)),
      );

      expect(tableOf(tester).children.single.decoration, isNull);

      await tester.pumpWidget(
        wrap(
          TableNodeView(
            node: TableNode(
              children: [
                TableRowNode(children: [cell('only')]),
              ],
            ),
            scope: const NaturalBlockScope(),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tableOf(tester).children.single.children, hasLength(1));
    });

    testWidgets('a ragged row is squared off to the table width', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          TableNodeView(
            node: TableNode(
              children: [
                TableRowNode(children: [cell('a'), cell('b')]),
                TableRowNode(children: [cell('c')]),
              ],
            ),
            scope: const NaturalBlockScope(),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final rows = tableOf(tester).children;
      expect([for (final r in rows) r.children.length], [2, 2]);
    });

    testWidgets('a cell that stated nothing is drawn with its column', (
      tester,
    ) async {
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

      await pump(tester, source);

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

  group('builders', () {
    testWidgets('cells are built through the builders', (tester) async {
      final builders = NaturalBlockBuilders(
        tableCell: (node, scope) => const Placeholder(),
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
            scope: NaturalBlockScope(builders: builders),
          ),
        ),
      );

      expect(find.byType(Placeholder), findsNWidgets(2));
    });

    testWidgets('a custom span inside a table cell is tappable', (
      tester,
    ) async {
      final tapped = <String>[];
      await tester.pumpWidget(
        wrap(
          NaturalBlockView(
            source: '~:@tap:@^B|C^D~',
            customs: [
              (text, style, theme) =>
                  tappableText(text, style, onTap: tapped.add),
            ],
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
