import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

import 'rendered_spans.dart';

/// A handler that draws any custom run as a box, for the selection
/// tests: a WidgetSpan is what splits a paragraph's selection into
/// segments.
RunRendering? _boxed(String text, TextStyle style, NaturalBlockTheme theme) =>
    widgetRun(const SizedBox(width: 20, height: 10));

void _ignore(String _) {}

RunRendering? _links(String text, TextStyle style, NaturalBlockTheme theme) =>
    tappableText(text, style, onTap: _ignore);

void main() {
  Future<void> pump(
    WidgetTester tester,
    String source, {
    NaturalBlockTheme theme = const NaturalBlockTheme(),
    NaturalBlockBuilders builders = NaturalBlockBuilders.defaults,
  }) => tester.pumpWidget(
    MaterialApp(
      home: NaturalBlockView(source: source, theme: theme, builders: builders),
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

  group('the default theme', () {
    // No constant can be right in both a light and a dark theme -- the same
    // reason striping is offered only on `fromColorScheme`. So a view given
    // no theme derives one from the surrounding ColorScheme rather than
    // falling back to a fixed red.
    const error = Color(0xFF00AAFF);

    final themed = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo)
          .copyWith(error: error),
    );

    testWidgets('a view given no theme takes its tones from the ambient '
        'ColorScheme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: themed,
          home: const NaturalBlockView(source: ':!tone'),
        ),
      );

      expect(renderedSpans(tester).first.style!.color, error);
    });

    testWidgets('a theme passed in still wins over the ambient one', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: themed,
          home: const NaturalBlockView(
            source: ':!tone',
            theme: NaturalBlockTheme(negative: TextStyle(color: Colors.red)),
          ),
        ),
      );

      expect(renderedSpans(tester).first.style!.color, Colors.red);
    });
  });

  group('decoration rendering (end-to-end)', () {
    testWidgets('markup in the source reaches the screen as style', (
      tester,
    ) async {
      // The package's whole purpose, as one assertion: a cluster in a
      // `source` comes out the far end of parse -> builders -> widget as the
      // style the theme says it means. What any cluster means is the theme's
      // own test; that each run gets its own is `TextNodeView`'s.
      //
      // Repeating the cluster shows the asymmetry between the markers, which
      // only drawn text makes visible: `:!` and `:*` toggle off, `:+` is a
      // step and stacks.
      const theme = NaturalBlockTheme();
      const ambientSize = 20.0;

      await tester.pumpWidget(
        MaterialApp(
          home: DefaultTextStyle(
            style: const TextStyle(fontSize: ambientSize),
            child: const NaturalBlockView(
              source: ':!*+marked:!*+plain',
              theme: theme,
            ),
          ),
        ),
      );

      final spans = renderedSpans(tester);

      expect(spans[0].text, 'marked');
      expect(
        spans[0].style,
        theme.styleFor(
          const SpanDecoration(
            tone: Tone.negative,
            emphasis: true,
            sizeOffset: 1,
          ),
          baseSize: ambientSize,
        ),
      );

      expect(spans[1].text, 'plain');
      expect(
        spans[1].style,
        theme.styleFor(
          const SpanDecoration(sizeOffset: 2),
          baseSize: ambientSize,
        ),
        reason:
            'the toggles came off, and the second step stacked on the first',
      );
    });
  });

  group('theme and builder customization', () {
    testWidgets('a custom theme changes the rendered color', (tester) async {
      const customTheme = NaturalBlockTheme(
        negative: TextStyle(color: Colors.purple),
      );
      await pump(tester, ':!alert:!', theme: customTheme);

      final span = renderedSpans(tester).first;

      expect(span.style!.color, Colors.purple);
    });

    testWidgets('a custom builder substitutes a widget for a node type', (
      tester,
    ) async {
      final builders = NaturalBlockBuilders(
        text: (node, scope) => const Placeholder(),
      );

      await pump(tester, 'Hello world', builders: builders);

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
              customs: const [_boxed],
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

  group('the document is drawn once per source, not once per frame', () {
    // Nothing about the document depends on the BuildContext, but `build`
    // runs whenever an ancestor rebuilds. Counting is the only way to see
    // this: a rebuilt view renders identically whether or not it redrew, so
    // no assertion about the widgets it produces would ever catch a
    // regression.

    /// Builders that count how many times a document reaches them.
    ({NaturalBlockBuilders builders, List<int> builds}) counting() {
      final builds = <int>[];
      return (
        builds: builds,
        builders: NaturalBlockBuilders(
          text: (node, scope) {
            builds.add(1);
            return const SizedBox.shrink();
          },
        ),
      );
    }

    testWidgets('a handler reading an inherited widget sees it change', (
      tester,
    ) async {
      // A handler is handed no context either, and for a sharper reason than
      // a builder: a span cannot read one lazily, and the line compares what
      // it was built from, which cannot say what a handler went and read. A
      // handler that read a `MediaQuery` through a context it was given drew
      // the first value and then never moved. Through `widgetRun` the
      // dependency sits in an element of its own and Flutter tracks it.
      RunRendering? reads(
        String text,
        TextStyle style,
        NaturalBlockTheme theme,
      ) => widgetRun(
        Builder(
          builder: (context) =>
              Text('${MediaQuery.sizeOf(context).width.round()}'),
        ),
      );

      final customs = <RunHandler>[reads];
      Widget view(double width) => MediaQuery(
        data: MediaQueryData(size: Size(width, 600)),
        child: MaterialApp(
          home: NaturalBlockView(source: ':@x:@', customs: customs),
        ),
      );

      await tester.pumpWidget(view(300));
      expect(find.text('300'), findsOneWidget);

      await tester.pumpWidget(view(500));
      expect(find.text('500'), findsOneWidget);
    });

    testWidgets('a builder reading an inherited widget sees it change', (
      tester,
    ) async {
      // A builder is handed no context, so reading one goes through a
      // `Builder` -- which puts the dependency in an element of its own, for
      // Flutter to notify. The drawn tree is kept across the change and the
      // text still updates, which is the whole point of doing it this way.
      final builders = NaturalBlockBuilders(
        text: (node, scope) => Builder(
          builder: (context) =>
              Text('${MediaQuery.sizeOf(context).width.round()}'),
        ),
      );

      Widget view(double width) => MediaQuery(
        data: MediaQueryData(size: Size(width, 600)),
        child: MaterialApp(
          home: NaturalBlockView(source: 'anything', builders: builders),
        ),
      );

      await tester.pumpWidget(view(300));
      expect(find.text('300'), findsOneWidget);

      await tester.pumpWidget(view(500));
      expect(find.text('500'), findsOneWidget);
    });

    testWidgets('editing one line leaves the other lines as they were', (
      tester,
    ) async {
      // `buildSpan` is handed to the lines as it came rather than wrapped,
      // so a line compares it against the same object and keeps its spans.
      // Wrapping gave every line a fresh identity, and a one-line edit
      // rebuilt every line's spans and recognizers.
      var calls = 0;
      RunRendering? counting(
        String text,
        TextStyle style,
        NaturalBlockTheme theme,
      ) {
        calls++;
        return null;
      }

      // Held outside `view`, the way the docs ask: a list written afresh on
      // every build never compares equal, and every line would redraw.
      final customs = <RunHandler>[counting];

      Widget view(String source) => MaterialApp(
        home: NaturalBlockView(source: source, customs: customs),
      );

      await tester.pumpWidget(view('one :@a:@|two :@b:@'));
      expect(calls, 2, reason: 'both lines built their custom span');

      calls = 0;
      await tester.pumpWidget(view('ONE :@a:@|two :@b:@'));

      expect(calls, 1, reason: 'only the edited line builds its spans again');
    });

    testWidgets('every part of the scope reaches the comparison', (
      tester,
    ) async {
      // The hazard one value exists to prevent: a field that reaches the
      // drawing but not the comparison, so a change to it never redraws.
      // The source never changes here, so only the scope can catch any of
      // it -- drop a field from `NaturalBlockScope`'s equality and one of
      // these stops holding.
      const inert = <RunHandler>[];
      const wired = <RunHandler>[_links];

      Widget view({
        NaturalBlockTheme? theme,
        NaturalBlockBuilders builders = NaturalBlockBuilders.defaults,
        List<RunHandler> customs = wired,
      }) => MaterialApp(
        home: NaturalBlockView(
          source: ':@tap:@',
          theme: theme,
          builders: builders,
          customs: customs,
        ),
      );

      await tester.pumpWidget(view(customs: inert));
      expect(renderedSpans(tester).single.recognizer, isNull);

      await tester.pumpWidget(view());
      expect(
        renderedSpans(tester).single.recognizer,
        isNotNull,
        reason: 'customs',
      );

      // One change per step from here, or an earlier field's change redraws
      // the document and hides whether the field under test was compared.
      const sized = NaturalBlockTheme(custom: TextStyle(fontSize: 33));

      await tester.pumpWidget(view(theme: sized));
      expect(renderedSpans(tester).single.style!.fontSize, 33, reason: 'theme');

      await tester.pumpWidget(
        view(
          theme: sized,
          builders: NaturalBlockBuilders(
            text: (node, scope) => const Placeholder(),
          ),
        ),
      );
      expect(find.byType(Placeholder), findsOneWidget, reason: 'builders');
    });

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
                builders: counter.builders,
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
        afterFirst,
        reason:
            'the view hands back the very same tree, so nothing below it is '
            'built again -- not the parse, and not the widgets either',
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
