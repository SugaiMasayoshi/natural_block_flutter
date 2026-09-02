// 【解説】[テスト13/21] verbatim の描画。1つのノードを2通りに描く判断。
// 【解説】
// 【解説】 2つ目の group が核心で、置かれ方が見た目を決める。行の中身が
// 【解説】 区間だけなら枠付きのコードブロック、文中にあれば等幅のランになる。
// 【解説】 パーサは区別していないので、この判断は TextNodeView にしかない。
// 【解説】
// 【解説】 "layout safety" は、コードブロックを足したせいで文書が描けなく
// 【解説】 なることが無いという確認。幅が無限のところでも落ちない。
// 【解説】 次: test/widget/column_node_view_test.dart

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
      const code = 'final x = a == b ? 1 : 2;';

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
      // Same node either way -- where it was written is a question about
      // appearance, so the renderer is what answers it.
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
        wrap(const NaturalBlockView(source: '比較は`a == b`です')),
      );

      expect(decoratedBoxes(tester), isEmpty);
      expect(renderedText(tester), '比較はa == bです');

      final spans = renderedSpans(tester);
      expect(spans.map((s) => s.text), ['比較は', 'a == b', 'です']);
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
      // The package otherwise never puts a scroll view in a caller's layout,
      // so the default keeps that promise.
      await tester.pumpWidget(
        wrap(NaturalBlockView(source: '`${'word ' * 200}`')),
      );

      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(tester.widget<RichText>(find.byType(RichText)).softWrap, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('scroll sideways when the theme asks', (tester) async {
      // Wrapping is wrong for code -- a broken line reads as a different
      // program -- so this exists; it is opt-in because of what it costs.
      await tester.pumpWidget(
        wrap(
          NaturalBlockView(
            source: '`${'word ' * 200}`',
            theme: const NaturalBlockTheme(verbatimScrollsHorizontally: true),
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
                theme: const NaturalBlockTheme(
                  verbatimScrollsHorizontally: true,
                ),
              ),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('layout safety', () {
    testWidgets('renders where the available width is unbounded', (
      tester,
    ) async {
      // The box is never stretched to the width, for the same reason
      // ColumnNodeView uses Align rather than a width-filling SizedBox.
      await tester.pumpWidget(
        wrap(
          const Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: NaturalBlockView(source: '`code here`'),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(renderedText(tester), 'code here');
    });

    testWidgets('a region inside a table cell renders', (tester) async {
      // Only possible because the delimiter no longer involves `|`: a cell
      // holds lines, so it could never have held a block-shaped region.
      await tester.pumpWidget(
        wrap(const NaturalBlockView(source: '|~x=`a|b`|y=z|')),
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
            theme: NaturalBlockTheme(verbatimDecoration: null),
          ),
        ),
      );
      expect(decoratedBoxes(tester), isEmpty);
    });
  });

  group('selection', () {
    testWidgets('a verbatim region takes part in selection', (tester) async {
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
