// 【解説】[テスト20/21] 統合。文字列を渡してから画面に出るまでを通しで見る。
// 【解説】
// 【解説】 ここまでの各ファイルが部品を単体で見ているのに対し、これは
// 【解説】 パース→registry→ウィジェットの経路が実際に繋がっていることを
// 【解説】 見る。部品が全部正しくても繋ぎ忘れは起きるので、両方要る。
// 【解説】
// 【解説】 選択の group が地味に重要。RichText を直接組むと選択機構に
// 【解説】 登録されず、SelectionArea で囲んでも黙って何も起きない。
// 【解説】 「黙って」なので、テストが無ければ気づけない類の性質。
// 【解説】 次: test/showcase/showcase_test.dart

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
      await pump(tester, 'left line 1\nleft line 2^right');

      final row = tester.widget<Row>(find.byType(Row));
      expect(row.children, hasLength(2), reason: 'two cells, not three');
      expect(
        find.byType(TextNodeView),
        findsNWidgets(2),
        reason: 'one view per cell -- a newline no longer starts a new node',
      );
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
        await pump(tester, 'left^right');

        expect(find.byType(RowNodeView), findsOneWidget);
        expect(find.byType(Row), findsOneWidget);
        expect(find.byType(Expanded), findsNWidgets(2));
      },
    );

    testWidgets('renders column-separated content stacked vertically', (
      tester,
    ) async {
      await pump(tester, 'first|second');

      // One for the document, one for each of the two blocks it now holds.
      expect(find.byType(ColumnNodeView), findsNWidgets(3));
      expect(find.byType(TextNodeView), findsNWidgets(2));
    });

    testWidgets('"a^b|c^d" renders as two separate two-cell Rows, not one '
        'four-cell Row', (tester) async {
      // Regression: RowNode boundaries used to be implicit in sibling
      // adjacency, so a column of two row-blocks in a row could collapse
      // into a single merged Row of every cell.
      await pump(tester, 'a^b|c^d');

      expect(find.byType(RowNodeView), findsNWidgets(2));
      expect(find.byType(Row), findsNWidgets(2));

      final rows = tester.widgetList<Row>(find.byType(Row)).toList();
      for (final row in rows) {
        expect(row.children, hasLength(2));
      }
      expect(find.byType(Expanded), findsNWidgets(4));
    });
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
      const customTheme = NaturalBlockTheme(
        danger: TextStyle(color: Colors.purple),
      );
      await pump(tester, ':!alert:!', theme: customTheme);

      final span = renderedSpans(tester).first;

      expect(span.style!.color, Colors.purple);
    });

    testWidgets('a custom registry substitutes a widget for a node type', (
      tester,
    ) async {
      final registry = NaturalBlockRegistry.defaults.register(
        TextNode,
        (context, node, scope) => const Placeholder(),
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
    testWidgets('text registers for selection when wrapped in a SelectionArea, '
        'across every cell and row', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SelectionArea(child: NaturalBlockView(source: 'a^b|c^d')),
        ),
      );

      final texts = tester.widgetList<RichText>(find.byType(RichText));
      expect(texts, hasLength(4));
      expect(
        texts.every((t) => t.selectionRegistrar != null),
        isTrue,
        reason: 'every cell of every row must be selectable',
      );
    });

    testWidgets('a line containing a WidgetSpan still registers', (
      tester,
    ) async {
      // A span a caller builds -- an image, say -- becomes a WidgetSpan,
      // which splits the paragraph's selection into segments around it.
      // That is the likeliest place a drag across a line breaks, and the
      // other selection tests here use plain text only.
      await tester.pumpWidget(
        MaterialApp(
          home: SelectionArea(
            child: NaturalBlockView(
              source: 'before :@boxed:@ after',
              onActionBuild: (context, text, style, theme) => WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: SizedBox(width: 20, height: 10),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      final text = tester.widget<RichText>(find.byType(RichText));
      expect(text.selectionRegistrar, isNotNull);
      // The placeholder shows up as U+FFFC, so a copied selection loses the
      // text that named it -- the cost of replacing a run, noted in the docs.
      expect(text.text.toPlainText(), contains('￼'));
      expect(
        text.text.toPlainText(includePlaceholders: false),
        'before  after',
      );
    });

    testWidgets('without a SelectionArea nothing registers for selection', (
      tester,
    ) async {
      await pump(tester, 'hello');

      final text = tester.widget<RichText>(find.byType(RichText));
      expect(text.selectionRegistrar, isNull);
    });
  });

  group('block alignment (end-to-end)', () {
    // Measures real glyph geometry rather than just widget properties, to
    // prove the block actually moved rather than only that the plumbing
    // set the right enum value.
    //
    // `ColumnNodeView` is `mainAxisSize.min`, so it only visibly reacts to
    // `crossAxisAlignment` when its parent actually offers width beyond its
    // content -- a bare `pump()` lets the widget shrink-wrap and would leave
    // this proving nothing. The `SizedBox` gives it a fixed 800-wide surface
    // to align within, matching the geometry this feature was designed
    // against.
    Future<void> pumpWide(WidgetTester tester, String source) =>
        tester.pumpWidget(
          MaterialApp(
            home: SizedBox(width: 800, child: NaturalBlockView(source: source)),
          ),
        );

    Rect glyphRect(WidgetTester tester, RichText richText) {
      final renderParagraph = tester.renderObject<RenderParagraph>(
        find.byWidget(richText),
      );
      final boxes = renderParagraph.getBoxesForSelection(
        TextSelection(
          baseOffset: 0,
          extentOffset: renderParagraph.text.toPlainText().length,
        ),
      );
      final box = boxes.single;
      final topLeft = renderParagraph.localToGlobal(Offset(box.left, box.top));
      final bottomRight = renderParagraph.localToGlobal(
        Offset(box.right, box.bottom),
      );
      return Rect.fromPoints(topLeft, bottomRight);
    }

    testWidgets('|<A^>B| aligns A to the left and B to the right', (
      tester,
    ) async {
      await pumpWide(tester, '|<A^>B|');

      final richTexts = tester
          .widgetList<RichText>(find.byType(RichText))
          .toList();
      expect(richTexts, hasLength(2));

      final aRect = glyphRect(tester, richTexts[0]);
      final bRect = glyphRect(tester, richTexts[1]);

      expect(aRect.left, closeTo(0, 1));
      expect(bRect.right, closeTo(800, 1));
    });

    testWidgets('|=A| centers the block', (tester) async {
      await pumpWide(tester, '|=A|');

      final richText = tester.widget<RichText>(find.byType(RichText));
      final rect = glyphRect(tester, richText);
      final center = (rect.left + rect.right) / 2;

      expect(center, closeTo(400, 1));
    });

    testWidgets('a source with no alignment markers is unchanged', (
      tester,
    ) async {
      await pump(tester, 'left|right');

      // Every block is a ColumnNode now, so there is more than one Column;
      // "unchanged" means none of them was given an alignment.
      final columns = tester.widgetList<Column>(find.byType(Column));
      expect(columns, isNotEmpty);
      for (final column in columns) {
        expect(column.crossAxisAlignment, CrossAxisAlignment.start);
      }
    });
  });

  group('block alignment in an unbounded width', () {
    // Align, not a width-filling SizedBox: a SizedBox of infinite width
    // throws where the available width is itself unbounded, which would
    // mean adding an alignment marker could stop a document rendering at
    // all. Align degrades to hugging its content there instead.
    for (final source in ['|=A|', '|>A|']) {
      testWidgets(
        '"$source" renders inside a horizontal scroll view without throwing',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: NaturalBlockView(source: source),
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull);
          expect(find.byType(RichText), findsOneWidget);
        },
      );
    }
  });

  group('row cell widths', () {
    // Measures real cell geometry rather than widget properties, so these
    // prove where the cells actually landed.
    double left(WidgetTester tester, String text) => tester
        .getTopLeft(
          find.byWidget(
            tester
                .widgetList<RichText>(find.byType(RichText))
                .firstWhere((w) => w.text.toPlainText() == text),
          ),
        )
        .dx;

    testWidgets(
      'cells split a bounded width equally, so columns line up across rows',
      (tester) async {
        // The reason RowNodeView uses Expanded at all: a RowNodeView cannot
        // see sibling rows, so equal fractions of a known width are the only
        // thing that makes consecutive rows share column positions.
        await tester.pumpWidget(
          const MaterialApp(
            home: NaturalBlockView(source: 'Apple^200^1000|Banana^1^2'),
          ),
        );

        // Asserted as a relationship rather than in absolute pixels: the
        // point is that the columns agree between rows and are evenly
        // spaced, whatever width the surface happens to be.
        final width = tester.getSize(find.byType(NaturalBlockView)).width;
        final third = width / 3;

        for (final row in [
          ['Apple', '200', '1000'],
          ['Banana', '1', '2'],
        ]) {
          expect(left(tester, row[0]), closeTo(0, 0.01));
          expect(left(tester, row[1]), closeTo(third, 0.01));
          expect(left(tester, row[2]), closeTo(2 * third, 0.01));
        }
      },
    );

    testWidgets('a row in an unbounded width shrink-wraps its cells instead of '
        'throwing', (tester) async {
      // Regression: cells were wrapped in Expanded unconditionally, and a
      // Row cannot lay out flex children when its own width is unbounded
      // -- so any document containing "^" threw inside a horizontal
      // scroll view, i.e. stopped rendering entirely.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: NaturalBlockView(source: 'Apple^200^1000'),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(RichText), findsNWidgets(3));

      // Cells are packed at their own content width, in order.
      expect(left(tester, 'Apple'), 0);
      expect(left(tester, '200'), greaterThan(0));
      expect(left(tester, '1000'), greaterThan(left(tester, '200')));
    });

    testWidgets('a row nested in another Row renders without throwing', (
      tester,
    ) async {
      // The other unbounded case: a parent Row gives its children unbounded
      // width on the main axis just as a horizontal scroll view does.
      await tester.pumpWidget(
        const MaterialApp(
          home: Row(children: [NaturalBlockView(source: 'a^b')]),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(RichText), findsNWidgets(2));
    });

    testWidgets(
      'the unbounded fallback is a degradation: columns stop lining up '
      'across rows',
      (tester) async {
        // Documents the accepted cost rather than asserting the fallback is
        // equivalent. With no width to divide there is nothing to keep the
        // rows in step, so a table stops reading as a table -- accepted
        // only because the alternative is not rendering at all.
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: NaturalBlockView(source: 'Apple^200|Banana^1'),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(
          left(tester, '200'),
          isNot(closeTo(left(tester, '1'), 0.01)),
          reason:
              'the second column of each row does not align when '
              'cells shrink-wrap',
        );
      },
    );
  });

  group('parsing happens once per source, not once per frame', () {
    // Nothing about the parse depends on the BuildContext, but `build` runs
    // whenever an ancestor rebuilds. Counting is the only way to see this:
    // a rebuilt view renders identically whether or not it re-parsed, so no
    // assertion about the widgets it produces would ever catch a regression.

    /// A registry that counts how many times a document reaches it.
    ({NaturalBlockRegistry registry, List<int> builds}) counting() {
      final builds = <int>[];
      return (
        builds: builds,
        registry: NaturalBlockRegistry.defaults.register(TextNode, (
          context,
          node,
          scope,
        ) {
          builds.add(1);
          return const SizedBox.shrink();
        }),
      );
    }

    testWidgets('an ancestor rebuild does not re-parse', (tester) async {
      final counter = counting();
      final rebuild = ValueNotifier<int>(0);
      addTearDown(rebuild.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<int>(
            valueListenable: rebuild,
            builder: (context, value, _) => Padding(
              padding: EdgeInsets.all(value.toDouble()),
              child: NaturalBlockView(
                source: 'one|two|three',
                registry: counter.registry,
              ),
            ),
          ),
        ),
      );

      final afterFirst = counter.builds.length;
      expect(afterFirst, 3, reason: 'three blocks on the first build');

      for (var i = 1; i <= 5; i++) {
        rebuild.value = i;
        await tester.pump();
      }

      expect(
        tester.widget<Padding>(find.byType(Padding).first).padding,
        const EdgeInsets.all(5),
        reason: 'the ancestor really did rebuild',
      );
      expect(
        counter.builds.length,
        afterFirst + 3 * 5,
        reason: 'widgets are rebuilt each frame -- the parse is not',
      );
    });

    testWidgets('changing the source re-parses', (tester) async {
      Future<void> pumpSource(WidgetTester tester, String source) => tester
          .pumpWidget(MaterialApp(home: NaturalBlockView(source: source)));

      await pumpSource(tester, 'first');
      expect(find.text('first', findRichText: true), findsOneWidget);

      await pumpSource(tester, 'second');
      expect(find.text('second', findRichText: true), findsOneWidget);
      expect(find.text('first', findRichText: true), findsNothing);
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

      expect(find.byType(ColumnNodeView), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  });
}
