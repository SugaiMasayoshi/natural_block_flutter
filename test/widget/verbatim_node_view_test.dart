import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
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

  group('content reaches the screen unchanged', () {
    testWidgets('code that would otherwise be split renders as one run', (
      tester,
    ) async {
      // The end-to-end version of the reason this feature exists: without
      // the region, `=` and `|` would have turned this into cells and
      // blocks before the renderer ever saw it.
      const code = 'final x = a == b ? 1 : 2;';

      await tester.pumpWidget(
        wrap(const NaturalBlockView(source: '|`$code|`')),
      );

      expect(find.byType(VerbatimNodeView), findsOneWidget);
      expect(renderedText(tester), code);
      expect(find.byType(RowNodeView), findsNothing);
    });

    testWidgets('newlines and indentation survive', (tester) async {
      await tester.pumpWidget(
        wrap(const NaturalBlockView(source: '|`\nif (x) {\n    y();\n}\n|`')),
      );

      expect(renderedText(tester), 'if (x) {\n    y();\n}');
    });

    testWidgets('the text is monospaced from the theme', (tester) async {
      await tester.pumpWidget(wrap(const NaturalBlockView(source: '|`x|`')));

      expect(renderedSpans(tester).single.style!.fontFamily, 'monospace');
    });
  });

  group('long lines', () {
    testWidgets('wrap by default, adding no scroll view', (tester) async {
      // The package otherwise never puts a scroll view in a caller's
      // layout, so the default keeps that promise.
      await tester.pumpWidget(
        wrap(NaturalBlockView(source: '|`${'word ' * 200}|`')),
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
            source: '|`${'word ' * 200}|`',
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
      // The interaction worth checking before shipping the option: a scroll
      // view inside another scrollable.
      await tester.pumpWidget(
        wrap(
          ListView(
            children: [
              NaturalBlockView(
                source: '|`${'word ' * 200}|`',
                theme: const NaturalBlockTheme(
                  verbatimScrollsHorizontally: true,
                ),
              ),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(VerbatimNodeView), findsOneWidget);
    });
  });

  group('layout safety', () {
    testWidgets('renders where the available width is unbounded', (
      tester,
    ) async {
      // The box is never stretched to the width, for the same reason
      // ColumnNodeView uses Align rather than a width-filling SizedBox:
      // adding a code block must not be able to stop a document rendering.
      await tester.pumpWidget(
        wrap(
          const Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: NaturalBlockView(source: '|`code here|`'),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(VerbatimNodeView), findsOneWidget);
    });
  });

  group('theming', () {
    testWidgets('the box comes from the theme and can be removed', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const NaturalBlockView(source: '|`x|`')));
      expect(
        tester
            .widget<Container>(
              find.ancestor(
                of: find.byType(RichText),
                matching: find.byType(Container),
              ),
            )
            .decoration,
        isNotNull,
      );

      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: '|`x|`',
            theme: NaturalBlockTheme(verbatimDecoration: null),
          ),
        ),
      );
      expect(
        tester
            .widget<Container>(
              find.ancestor(
                of: find.byType(RichText),
                matching: find.byType(Container),
              ),
            )
            .decoration,
        isNull,
      );
    });
  });

  group('selection', () {
    testWidgets('a verbatim region takes part in selection', (tester) async {
      // Code is exactly the kind of text a reader wants to copy, so this
      // uses Text.rich for the same reason TextNodeView does.
      await tester.pumpWidget(
        wrap(
          const SelectionArea(child: NaturalBlockView(source: '|`copy me|`')),
        ),
      );

      expect(
        tester.widget<RichText>(find.byType(RichText)).selectionRegistrar,
        isNotNull,
      );
    });
  });

  group('registry', () {
    testWidgets('a verbatim node has a builder, so it is never dropped', (
      tester,
    ) async {
      // An unregistered node type renders nothing at all, silently, in
      // release builds -- so the registration itself is worth pinning.
      await tester.pumpWidget(
        wrap(
          VerbatimNodeView(
            node: VerbatimNode(text: 'direct'),
            theme: const NaturalBlockTheme(),
          ),
        ),
      );
      expect(renderedText(tester), 'direct');

      await tester.pumpWidget(
        wrap(const NaturalBlockView(source: '|`via registry|`')),
      );
      expect(renderedText(tester), 'via registry');
    });

    testWidgets('an unterminated region still renders its content', (
      tester,
    ) async {
      // The content is not lost; the flag on the node is what tells a tool
      // that the rest of the document was swallowed.
      await tester.pumpWidget(
        wrap(const NaturalBlockView(source: '|`never closed')),
      );

      expect(renderedText(tester), 'never closed');
    });
  });
}
