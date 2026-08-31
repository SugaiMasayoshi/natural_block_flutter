import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

import 'rendered_spans.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    String source, {
    NaturalBlockTheme theme = const NaturalBlockTheme(),
    NaturalBlockRegistry registry = NaturalBlockRegistry.defaults,
  }) => tester.pumpWidget(
    MaterialApp(
      home: NaturalBlockView(source: source, theme: theme, registry: registry),
    ),
  );

  group('structural rendering', () {
    testWidgets('a multi-line row cell stacks its lines instead of splitting '
        'them into separate cells', (tester) async {
      // Regression: RowNodeView used to flatten every RowNode's children into
      // the Row, so a two-line left cell rendered as two side-by-side cells.
      await pump(tester, 'left line 1\nleft line 2=right');

      final row = tester.widget<Row>(find.byType(Row));
      expect(row.children, hasLength(2), reason: 'two cells, not three');
      expect(find.byType(TextNodeView), findsNWidgets(3));
    });

    testWidgets('renders plain text as a single RichText', (tester) async {
      await pump(tester, 'Hello world');

      expect(find.byType(RichText), findsOneWidget);
      final richText = tester.widget<RichText>(find.byType(RichText));
      expect(richText.text.toPlainText(), 'Hello world');
      expect(find.byType(RowNodeView), findsNothing);
    });

    testWidgets(
      'renders row-separated content as one Row with Expanded cells',
      (tester) async {
        await pump(tester, 'left=right');

        expect(find.byType(RowNodeView), findsOneWidget);
        expect(find.byType(Row), findsOneWidget);
        expect(find.byType(Expanded), findsNWidgets(2));
      },
    );

    testWidgets(
      'renders column-separated content stacked vertically', (
      tester,
    ) async {
      await pump(tester, 'first|second');

      expect(find.byType(ColumnNodeView), findsOneWidget);
      expect(find.byType(TextNodeView), findsNWidgets(2));
    });

    testWidgets(
      '"a=b|c=d" renders as two separate two-cell Rows, not one '
      'four-cell Row',
      (tester) async {
        // Regression: RowNode boundaries used to be implicit in sibling
        // adjacency, so a column of two row-blocks in a row could collapse
        // into a single merged Row of every cell.
        await pump(tester, 'a=b|c=d');

        expect(find.byType(RowNodeView), findsNWidgets(2));
        expect(find.byType(Row), findsNWidgets(2));

        final rows = tester.widgetList<Row>(find.byType(Row)).toList();
        for (final row in rows) {
          expect(row.children, hasLength(2));
        }
        expect(find.byType(Expanded), findsNWidgets(4));
      },
    );
  });

  group('decoration rendering (end-to-end)', () {
    // This is the package's whole purpose: verifying that decoration markup
    // in a `source` string actually reaches the screen as styled text,
    // through the full parse -> registry -> widget pipeline.

    testWidgets(':! toggles danger (red) color on and off', (tester) async {
      await pump(tester, ':!danger:!plain');

      final spans = renderedSpans(tester);

      expect(spans[0].text, 'danger');
      expect(spans[0].style!.color, Colors.red);
      expect(spans[1].text, 'plain');
      expect(spans[1].style!.color, isNot(Colors.red));
    });

    testWidgets(':* toggles bold emphasis on and off', (tester) async {
      await pump(tester, ':*bold:*');

      final span = renderedSpans(tester).first;

      expect(span.text, 'bold');
      expect(span.style!.fontWeight, FontWeight.bold);
    });

    testWidgets(':+ increases the rendered font size', (tester) async {
      const theme = NaturalBlockTheme();
      const ambientFontSize = 20.0;

      await tester.pumpWidget(
        MaterialApp(
          home: DefaultTextStyle(
            style: const TextStyle(fontSize: ambientFontSize),
            child: NaturalBlockView(source: ':+big', theme: theme),
          ),
        ),
      );

      final span = renderedSpans(tester).first;

      expect(span.text, 'big');
      expect(span.style!.fontSize, ambientFontSize + theme.fontSizeStep);
    });
  });

  group('theme and registry customization', () {
    testWidgets('a custom theme changes the rendered color', (tester) async {
      const customTheme = NaturalBlockTheme(danger: TextStyle(color: Colors.purple));
      await pump(tester, ':!alert:!', theme: customTheme);

      final span = renderedSpans(tester).first;

      expect(span.style!.color, Colors.purple);
    });

    testWidgets('a custom registry substitutes a widget for a node type', (
      tester,
    ) async {
      final registry = NaturalBlockRegistry.defaults.register(
        TextNode,
        (context, node, theme, registry) => const Placeholder(),
      );

      await pump(tester, 'Hello world', registry: registry);

      expect(find.byType(Placeholder), findsOneWidget);
      expect(find.byType(TextNodeView), findsNothing);
    });
  });

  group('text selection', () {
    // Built with Text.rich rather than a bare RichText specifically so the
    // rendered text takes part in selection. A directly-constructed
    // RichText never registers with the selection machinery, so wrapping it
    // in a SelectionArea would silently do nothing.
    testWidgets(
      'text registers for selection when wrapped in a SelectionArea, '
      'across every cell and row',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: SelectionArea(child: NaturalBlockView(source: 'a=b|c=d')),
          ),
        );

        final texts = tester.widgetList<RichText>(find.byType(RichText));
        expect(texts, hasLength(4));
        expect(
          texts.every((t) => t.selectionRegistrar != null),
          isTrue,
          reason: 'every cell of every row must be selectable',
        );
      },
    );

    testWidgets('without a SelectionArea nothing registers for selection', (
      tester,
    ) async {
      await pump(tester, 'hello');

      final text = tester.widget<RichText>(find.byType(RichText));
      expect(text.selectionRegistrar, isNull);
    });
  });

  group('edge cases', () {
    testWidgets('an empty source renders an empty Column', (tester) async {
      await pump(tester, '');

      expect(find.byType(ColumnNodeView), findsOneWidget);
      expect(find.byType(RichText), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a whitespace-only source renders without throwing', (
      tester,
    ) async {
      await pump(tester, '   ');

      expect(find.byType(ColumnNodeView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
