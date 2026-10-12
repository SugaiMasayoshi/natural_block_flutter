import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

import '../rendered_spans.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: DefaultTextStyle(
      style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
      child: child,
    ),
  );

  String renderedText(WidgetTester tester) =>
      tester.widget<RichText>(find.byType(RichText)).text.toPlainText();

  Iterable<Container> decoratedBoxes(WidgetTester tester) => tester
      .widgetList<Container>(find.byType(Container))
      .where((c) => c.decoration != null);

  group('content reaches the screen unchanged', () {
    testWidgets('code that would otherwise be split renders as one run', (
      tester,
    ) async {
      const code = 'final x ^ a ^^ b ? 1 : 2;';

      await tester.pumpWidget(wrap(const NaturalBlockView(source: '`$code`')));

      expect(renderedText(tester), code);
      expect(find.byType(RowNodeView), findsNothing);
    });

    testWidgets('newlines and indentation survive', (tester) async {
      await tester.pumpWidget(
        wrap(const NaturalBlockView(source: '`\nif (x) {\n    y();\n}\n`')),
      );

      expect(renderedText(tester), 'if (x) {\n    y();\n}');
    });
  });

  group('placement decides the presentation', () {
    testWidgets('a region alone on its line is drawn as a code block', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const NaturalBlockView(source: '`cat a | grep b`')),
      );

      expect(decoratedBoxes(tester), hasLength(1));
      expect(renderedText(tester), 'cat a | grep b');
    });

    testWidgets('a region inside a sentence is a run, with no box', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(const NaturalBlockView(source: '比較は`a ^^ b`です')),
      );

      expect(decoratedBoxes(tester), isEmpty);
      expect(renderedText(tester), '比較はa ^^ bです');

      final spans = renderedSpans(tester);
      expect(spans.map((s) => s.text), ['比較は', 'a ^^ b', 'です']);
      expect(
        spans[1].style!.fontFamily,
        'monospace',
        reason: 'only the region itself is monospaced',
      );
      expect(spans[0].style!.fontFamily, isNot('monospace'));
    });
  });

  group('long lines', () {
    testWidgets('wrap by default, adding no scroll view', (tester) async {
      await tester.pumpWidget(
        wrap(NaturalBlockView(source: '`${'word ' * 200}`')),
      );

      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(tester.widget<RichText>(find.byType(RichText)).softWrap, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('scroll sideways when the theme asks', (tester) async {
      await tester.pumpWidget(
        wrap(
          NaturalBlockView(
            source: '`${'word ' * 200}`',
            theme: const NaturalBlockTheme(rawScrollsHorizontally: true),
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(
        tester.widget<RichText>(find.byType(RichText)).softWrap,
        isFalse,
        reason: 'wrapping would leave the scroll view nothing to scroll',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('scrolling still works inside a scrolling parent', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          ListView(
            children: [
              NaturalBlockView(
                source: '`${'word ' * 200}`',
                theme: const NaturalBlockTheme(rawScrollsHorizontally: true),
              ),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('layout safety', () {
    testWidgets('a region inside a table cell renders', (tester) async {
      await tester.pumpWidget(
        wrap(const NaturalBlockView(source: '~x^`a|b`|y^z~')),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(Table), findsOneWidget);
      expect(
        tester
            .widgetList<RichText>(find.byType(RichText))
            .map((w) => w.text.toPlainText()),
        contains('a|b'),
      );
    });
  });

  group('theming', () {
    testWidgets('the box comes from the theme and can be removed', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const NaturalBlockView(source: '`x`')));
      expect(decoratedBoxes(tester), hasLength(1));

      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: '`x`',
            theme: NaturalBlockTheme(rawDecoration: BoxDecoration()),
          ),
        ),
      );
      expect(decoratedBoxes(tester).single.decoration, const BoxDecoration());
    });

    testWidgets('the base style of the theme reaches a raw block', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: '`x`',
            theme: NaturalBlockTheme(base: TextStyle(fontSize: 30)),
          ),
        ),
      );

      expect(renderedSpans(tester).single.style!.fontSize, 30);
    });
  });

  group('selection', () {
    testWidgets('a raw region takes part in selection', (tester) async {
      await tester.pumpWidget(
        wrap(const SelectionArea(child: NaturalBlockView(source: '`copy me`'))),
      );

      expect(
        tester.widget<RichText>(find.byType(RichText)).selectionRegistrar,
        isNotNull,
      );
    });
  });
}
