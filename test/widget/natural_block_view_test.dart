import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

import '../rendered_spans.dart';

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
      await pump(tester, 'left line 1\nleft line 2^right');

      final row = tester.widget<Row>(find.byType(Row));
      expect(row.children, hasLength(2), reason: 'two cells, not three');
      expect(
        find.byType(TextNodeView),
        findsNWidgets(2),
        reason: 'one view per cell -- a newline no longer starts a new node',
      );
    });

    testWidgets('"a^b|c^d" renders as two separate two-cell Rows, not one '
        'four-cell Row', (tester) async {
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
      expect(text.text.toPlainText(), contains('￼'));
      expect(
        text.text.toPlainText(includePlaceholders: false),
        'before  after',
      );
    });
  });

  group('the document is drawn once per source, not once per frame', () {
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
      var calls = 0;
      RunRendering? counting(
        String text,
        TextStyle style,
        NaturalBlockTheme theme,
      ) {
        calls++;
        return null;
      }

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

    testWidgets('every kind of block renders in an unbounded width', (
      tester,
    ) async {
      for (final source in [
        'plain',
        '|=A|',
        '|>A|',
        '`code here`',
        'a^b',
        '|=~A^B|C^D~',
        '   ',
      ]) {
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

        expect(tester.takeException(), isNull, reason: '"$source"');
      }
    });
  });
}
