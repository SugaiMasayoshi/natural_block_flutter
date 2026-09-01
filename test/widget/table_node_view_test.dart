import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

import '../rendered_spans.dart';

void main() {
  const theme = NaturalBlockTheme();

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
          tester.widgetList<RichText>(find.byType(RichText)).firstWhere(
            (w) => w.text.toPlainText() == text,
          ),
        ),
      )
      .left;

  group('column widths', () {
    testWidgets(
      'columns fit their content and agree across rows',
      (tester) async {
        // The reason tables are declared separately from plain rows: a
        // TableNode holds every row, so its columns can be sized to their
        // content and still line up. A RowNodeView cannot do this -- it
        // renders one row and cannot see its siblings.
        await tester.pumpWidget(
          wrap(
            const NaturalBlockView(source: '|~Item=Price|Apple=200|Banana=1|'),
          ),
        );

        expect(find.byType(Table), findsOneWidget);

        final firstColumn = ['Item', 'Apple', 'Banana'].map(
          (t) => leftOf(tester, t),
        );
        final secondColumn = ['Price', '200', '1'].map(
          (t) => leftOf(tester, t),
        );

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
      },
    );

    testWidgets(
      'the same rows without the marker still split the width evenly',
      (tester) async {
        // Guards the pair of policies against being accidentally unified:
        // plain rows must keep dividing the available width, because that
        // is what makes `LEFT==RIGHT` push RIGHT to the far edge.
        await tester.pumpWidget(
          wrap(const NaturalBlockView(source: 'Item=Price|Apple=200|')),
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
    testWidgets('`|~^` centers the table', (tester) async {
      // Meaningful only because the table is sized to its content: a
      // width-filling table would have nothing to be centered within.
      await tester.pumpWidget(wrap(const NaturalBlockView(source: '|~^A=B|')));

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
              child: NaturalBlockView(source: '|~^A=B|C=D|'),
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
        wrap(
          const NaturalBlockView(source: '|~A=B|C=D|', theme: padded),
        ),
      );

      expect(leftOf(tester, 'A'), 40);
    });

    testWidgets('the border comes from the theme and can be removed', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const NaturalBlockView(source: '|~A=B|C=D|')),
      );
      expect(tester.widget<Table>(find.byType(Table)).border, isNotNull);

      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: '|~A=B|C=D|',
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
        wrap(const NaturalBlockView(source: '|~A=B|C=D|')),
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
            source: '|~A=B|C=D|',
            theme: NaturalBlockTheme(tableStripe: Color(0xFFEEEEEE)),
          ),
        ),
      );
      final rows = tester.widget<Table>(find.byType(Table)).children;
      expect(rows[0].decoration, isNull, reason: 'the first row is unpainted');
      expect(rows[1].decoration, isNotNull);
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
                RowNode(children: [ColumnNode(children: []), ColumnNode()]),
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
          NaturalBlockView(
            source: '|~:@tap:@=B|C=D|',
            onActionTap: tapped.add,
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
