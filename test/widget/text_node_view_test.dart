import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

import '../rendered_spans.dart';

void main() {
  group('color and emphasis', () {
    testWidgets('renders each TextSpanNode with its semantic style', (
      tester,
    ) async {
      final node = TextNode(
        children: [
          TextSpanNode(
            text: 'negative',
            decoration: SpanDecoration(tone: Tone.negative),
          ),
          TextSpanNode(text: 'plain'),
        ],
      );
      const theme = NaturalBlockTheme();

      await tester.pumpWidget(
        MaterialApp(
          home: TextNodeView(
            node: node,
            scope: NaturalBlockScope(theme: theme),
          ),
        ),
      );

      final spans = renderedSpans(tester);

      expect(spans[0].text, 'negative');
      expect(spans[0].style!.color, theme.negative.color);
      expect(spans[1].text, 'plain');
    });

    testWidgets('combines color and emphasis on the same span', (tester) async {
      final node = TextNode(
        children: [
          TextSpanNode(
            text: 'urgent',
            decoration: SpanDecoration(tone: Tone.negative, emphasis: true),
          ),
        ],
      );
      const theme = NaturalBlockTheme();

      await tester.pumpWidget(
        MaterialApp(
          home: TextNodeView(
            node: node,
            scope: NaturalBlockScope(theme: theme),
          ),
        ),
      );

      final span = renderedSpans(tester).first;

      expect(span.style!.color, theme.negative.color);
      expect(span.style!.fontWeight, theme.emphasis.fontWeight);
    });
  });

  group('font size scaling', () {
    testWidgets('applies sizeOffset relative to the ambient font size', (
      tester,
    ) async {
      final node = TextNode(
        children: [
          TextSpanNode(text: 'big', decoration: SpanDecoration(sizeOffset: 2)),
        ],
      );
      const theme = NaturalBlockTheme();

      await tester.pumpWidget(
        MaterialApp(
          home: DefaultTextStyle(
            style: const TextStyle(fontSize: 14),
            child: TextNodeView(
              node: node,
              scope: NaturalBlockScope(theme: theme),
            ),
          ),
        ),
      );

      final span = renderedSpans(tester).first;

      expect(span.style!.fontSize, 14 + 2 * theme.fontSizeStep);
    });

    testWidgets('a size step counts from the size the theme actually draws, '
        'not from the ambient one', (tester) async {
      // The README's first theme example is `base: TextStyle(fontSize: 16)`,
      // and `theme.base` wins over the ambient `DefaultTextStyle` for the
      // root span. A sized run has to count from the same place, or `:+`
      // renders *smaller* than the text beside it.
      const theme = NaturalBlockTheme(base: TextStyle(fontSize: 24));
      final node = TextNode(
        children: [
          TextSpanNode(text: 'plain'),
          TextSpanNode(
            text: 'bigger',
            decoration: SpanDecoration(sizeOffset: 1),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: DefaultTextStyle(
            style: const TextStyle(fontSize: 14),
            child: TextNodeView(
              node: node,
              scope: NaturalBlockScope(theme: theme),
            ),
          ),
        ),
      );

      final spans = renderedSpans(tester);

      expect(
        spans[0].style!.fontSize,
        24,
        reason: 'theme.base wins over the ambient style',
      );
      expect(spans[1].style!.fontSize, 24 + theme.fontSizeStep);
      expect(
        spans[1].style!.fontSize,
        greaterThan(spans[0].style!.fontSize!),
        reason: 'an enlarging marker must not shrink the text',
      );
    });

    testWidgets('clamps a large negative sizeOffset to minFontSize instead of '
        'producing a zero or negative font size', (tester) async {
      final node = TextNode(
        children: [
          TextSpanNode(
            text: 'tiny',
            decoration: SpanDecoration(sizeOffset: -5),
          ),
        ],
      );
      const theme = NaturalBlockTheme();

      await tester.pumpWidget(
        MaterialApp(
          home: DefaultTextStyle(
            style: const TextStyle(fontSize: 14),
            child: TextNodeView(
              node: node,
              scope: NaturalBlockScope(theme: theme),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      final span = renderedSpans(tester).first;

      expect(span.style!.fontSize, theme.minFontSize);
      expect(span.style!.fontSize, greaterThan(0));
    });
  });

  group('actionable spans', () {
    testWidgets('applies the action style to an actionable span', (
      tester,
    ) async {
      final node = TextNode(
        children: [
          TextSpanNode(
            text: 'tap me',
            decoration: SpanDecoration(isAction: true),
          ),
        ],
      );
      const theme = NaturalBlockTheme();

      await tester.pumpWidget(
        MaterialApp(
          home: TextNodeView(
            node: node,
            scope: NaturalBlockScope(theme: theme),
          ),
        ),
      );

      final span = renderedSpans(tester).first;
      expect(span.style!.color, theme.action.color);
      expect(span.style!.decoration, theme.action.decoration);
    });

    testWidgets('combines action and emphasis styles on the same span', (
      tester,
    ) async {
      final node = TextNode(
        children: [
          TextSpanNode(
            text: 'tap me',
            decoration: SpanDecoration(isAction: true, emphasis: true),
          ),
        ],
      );
      const theme = NaturalBlockTheme();

      await tester.pumpWidget(
        MaterialApp(
          home: TextNodeView(
            node: node,
            scope: NaturalBlockScope(theme: theme),
          ),
        ),
      );

      final span = renderedSpans(tester).first;
      expect(span.style!.color, theme.action.color);
      expect(span.style!.decoration, theme.action.decoration);
      expect(span.style!.fontWeight, theme.emphasis.fontWeight);
    });

    testWidgets('an actionable span gets a recognizer when onTap is given', (
      tester,
    ) async {
      final node = TextNode(
        children: [
          TextSpanNode(
            text: 'tap me',
            decoration: SpanDecoration(isAction: true),
          ),
        ],
      );
      const theme = NaturalBlockTheme();

      await tester.pumpWidget(
        MaterialApp(
          home: TextNodeView(
            node: node,
            scope: NaturalBlockScope(theme: theme, onTap: (_) {}),
          ),
        ),
      );

      final span = renderedSpans(tester).first;
      expect(span.recognizer, isA<TapGestureRecognizer>());
    });

    testWidgets('an actionable span gets no recognizer when onTap is null', (
      tester,
    ) async {
      final node = TextNode(
        children: [
          TextSpanNode(
            text: 'tap me',
            decoration: SpanDecoration(isAction: true),
          ),
        ],
      );
      const theme = NaturalBlockTheme();

      await tester.pumpWidget(
        MaterialApp(
          home: TextNodeView(
            node: node,
            scope: NaturalBlockScope(theme: theme),
          ),
        ),
      );

      final span = renderedSpans(tester).first;
      expect(span.recognizer, isNull);
    });

    testWidgets('a non-actionable span gets no recognizer', (tester) async {
      final node = TextNode(children: [TextSpanNode(text: 'plain')]);
      const theme = NaturalBlockTheme();

      await tester.pumpWidget(
        MaterialApp(
          home: TextNodeView(
            node: node,
            scope: NaturalBlockScope(theme: theme, onTap: (_) {}),
          ),
        ),
      );

      final span = renderedSpans(tester).first;
      expect(span.recognizer, isNull);
    });

    testWidgets('tapping an actionable span calls onTap with exactly that '
        "span's text", (tester) async {
      final tapped = <String>[];
      final node = TextNode(
        children: [
          TextSpanNode(
            text: 'actionable',
            decoration: SpanDecoration(isAction: true),
          ),
          TextSpanNode(text: ' plain'),
        ],
      );
      const theme = NaturalBlockTheme();

      await tester.pumpWidget(
        MaterialApp(
          home: TextNodeView(
            node: node,
            scope: NaturalBlockScope(theme: theme, onTap: tapped.add),
          ),
        ),
      );

      final span = renderedSpans(tester).first;
      (span.recognizer as TapGestureRecognizer).onTap!();

      expect(tapped, ['actionable']);
    });

    testWidgets('tapping a non-actionable span does not fire onTap', (
      tester,
    ) async {
      final tapped = <String>[];
      final node = TextNode(
        children: [
          TextSpanNode(
            text: 'actionable',
            decoration: SpanDecoration(isAction: true),
          ),
          TextSpanNode(text: ' plain'),
        ],
      );
      const theme = NaturalBlockTheme();

      await tester.pumpWidget(
        MaterialApp(
          home: TextNodeView(
            node: node,
            scope: NaturalBlockScope(theme: theme, onTap: tapped.add),
          ),
        ),
      );

      // Actually tapped, on the plain half of a line whose other half is
      // actionable. Asserting only that the span carries no recognizer
      // would say nothing about a stray one somewhere above it.
      await tester.tapOnText(find.textRange.ofSubstring('plain'));
      await tester.pump();

      expect(tapped, isEmpty);
    });

    testWidgets('only a run that actually does something is announced', (
      tester,
    ) async {
      // Style follows the document -- it said the run is actionable, so it
      // renders as such either way. Semantics follow what will actually
      // happen: telling a screen reader a run is interactive when no
      // handler is wired is a promise nothing keeps.
      final node = TextNode(
        children: [
          TextSpanNode(
            text: 'tap me',
            decoration: SpanDecoration(isAction: true),
          ),
        ],
      );
      const theme = NaturalBlockTheme();

      await tester.pumpWidget(
        MaterialApp(
          home: TextNodeView(
            node: node,
            scope: NaturalBlockScope(theme: theme),
          ),
        ),
      );
      final inert = renderedSpans(tester).single;
      expect(inert.style!.decoration, theme.action.decoration);
      expect(
        inert.semanticsLabel,
        isNull,
        reason: 'no handler, so nothing is announced as interactive',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TextNodeView(
            node: node,
            scope: NaturalBlockScope(theme: theme, onTap: (_) {}),
          ),
        ),
      );
      expect(renderedSpans(tester).single.semanticsLabel, 'tap me');
    });

    group('the spans, and the recognizers they carry', () {
      // The property the whole design turns on. A recognizer that has taken
      // a pointer down owns an entry in the gesture arena; replacing it
      // mid-gesture throws that entry away. The spans are built outside
      // `build` so that the recognizers survive a rebuild -- see the
      // interrupted-tap test below.
      TextSpanNode action(String text) =>
          TextSpanNode(text: text, decoration: SpanDecoration(isAction: true));

      Future<void> pumpRuns(
        WidgetTester tester,
        List<InlineNode> runs, {
        NaturalBlockTheme theme = const NaturalBlockTheme(),
        OnActionTap? onTap,
        TextStyle? ambient,
      }) {
        final view = TextNodeView(
          node: TextNode(children: runs),
          scope: NaturalBlockScope(
            theme: theme,
            // A fresh closure each time, the way a caller writing it inline
            // in their own `build` would hand one over.
            onTap: onTap ?? (_) {},
          ),
        );
        return tester.pumpWidget(
          MaterialApp(
            home: ambient == null
                ? view
                : DefaultTextStyle(style: ambient, child: view),
          ),
        );
      }

      GestureRecognizer? recognizerOf(WidgetTester tester, [int index = 0]) =>
          renderedSpans(tester)[index].recognizer;

      testWidgets('a rebuild with the same runs keeps the recognizer', (
        tester,
      ) async {
        await pumpRuns(tester, [action('tap me')]);
        final first = recognizerOf(tester);

        await pumpRuns(tester, [action('tap me')]);

        expect(recognizerOf(tester), same(first));
      });

      testWidgets('an ambient change the spans do not see keeps them', (
        tester,
      ) async {
        // The spans compare what they are made of, and what they are made of
        // is the *merged* style. An ambient size the theme's `base` overrides
        // never reaches them, so it is not a reason to replace a recognizer
        // -- and replacing one mid-gesture loses the tap.
        const theme = NaturalBlockTheme(base: TextStyle(fontSize: 20));

        await pumpRuns(
          tester,
          [action('tap me')],
          theme: theme,
          ambient: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
        );
        final first = recognizerOf(tester);

        await pumpRuns(
          tester,
          [action('tap me')],
          theme: theme,
          ambient: const TextStyle(fontSize: 30, color: Color(0xFF000000)),
        );

        expect(recognizerOf(tester), same(first));
      });

      testWidgets('rebuilding and then unmounting disposes once', (
        tester,
      ) async {
        // The spans release their recognizers when they are replaced, and
        // the view releases them again when it goes away. Disposing a
        // recognizer twice throws, so the second call must find nothing.
        await pumpRuns(tester, [action('one')]);
        await pumpRuns(tester, [action('two')]);

        await tester.pumpWidget(const SizedBox.shrink());

        expect(tester.takeException(), isNull);
      });

      testWidgets('a fresh onTap closure is not a reason to rebuild', (
        tester,
      ) async {
        // What makes the above hold for a real caller: `onTap` is read at tap
        // time, so its identity is deliberately left out of the comparison.
        // Comparing it would miss every time, since two closures are never
        // equal in Dart even when they read the same.
        await pumpRuns(tester, [action('tap me')], onTap: (_) {});
        final first = recognizerOf(tester);

        await pumpRuns(tester, [action('tap me')], onTap: (_) {});

        expect(recognizerOf(tester), same(first));
      });

      testWidgets('the onTap called is the one the caller passed last', (
        tester,
      ) async {
        final calls = <String>[];
        await pumpRuns(tester, [action('x')], onTap: (t) => calls.add('第1 $t'));
        await pumpRuns(tester, [action('x')], onTap: (t) => calls.add('第2 $t'));

        (recognizerOf(tester)! as TapGestureRecognizer).onTap!();

        expect(calls, ['第2 x']);
      });

      testWidgets('changed runs rebuild the spans', (tester) async {
        // The accepted cost: a tap held across an edit to this line is lost.
        await pumpRuns(tester, [action('tap me')]);
        final first = recognizerOf(tester);

        await pumpRuns(tester, [action('tap again')]);

        expect(recognizerOf(tester), isNot(same(first)));
      });

      testWidgets('a changed theme rebuilds the spans', (tester) async {
        await pumpRuns(tester, [action('tap me')]);
        final first = recognizerOf(tester);

        await pumpRuns(tester, [
          action('tap me'),
        ], theme: const NaturalBlockTheme(fontSizeStep: 9));

        expect(recognizerOf(tester), isNot(same(first)));
      });

      testWidgets('a changed ambient text style rebuilds the spans', (
        tester,
      ) async {
        // Reached through didChangeDependencies rather than didUpdateWidget:
        // `DefaultTextStyle` decides what every run starts from and can
        // change without any of this widget's own fields changing.
        await pumpRuns(tester, [
          action('tap me'),
        ], ambient: const TextStyle(fontSize: 14));
        final first = recognizerOf(tester);

        await pumpRuns(tester, [
          action('tap me'),
        ], ambient: const TextStyle(fontSize: 22));

        expect(recognizerOf(tester), isNot(same(first)));
      });
    });

    testWidgets('a tap interrupted by a rebuild still fires', (tester) async {
      // The regression this design exists for, and the only test here that
      // exercises the real gesture path -- calling `recognizer.onTap!()`
      // directly bypasses the arena, so it cannot see this at all.
      //
      // Rebuilds between a pointer down and its up are ordinary: an
      // animation, an ambient InheritedWidget changing, a SelectionArea
      // updating during a drag. When `build` recreated recognizers, the one
      // holding the down was disposed and the tap vanished silently.
      final tapped = <String>[];

      Future<void> pump(String suffix) => tester.pumpWidget(
        MaterialApp(
          home: DefaultTextStyle(
            style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
            child: TextNodeView(
              node: TextNode(
                children: [
                  TextSpanNode(
                    text: 'press',
                    decoration: SpanDecoration(isAction: true),
                  ),
                ],
              ),
              // A different theme instance each time, so the rebuild is
              // real work rather than an identical widget Flutter can skip.
              scope: NaturalBlockScope(
                theme: NaturalBlockTheme(
                  base: TextStyle(letterSpacing: suffix.length * 0.0),
                ),
                onTap: tapped.add,
              ),
            ),
          ),
        ),
      );

      await pump('a');

      final paragraph = tester.renderObject<RenderParagraph>(
        find.byType(RichText),
      );
      final box = paragraph
          .getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 5),
          )
          .single;
      final target = paragraph.localToGlobal(
        Offset((box.left + box.right) / 2, (box.top + box.bottom) / 2),
      );

      final gesture = await tester.startGesture(target);
      await pump('bb'); // rebuild while the pointer is still down
      await gesture.up();
      await tester.pump();

      expect(tapped, [
        'press',
      ], reason: 'the tap must survive a rebuild between down and up');
    });

    testWidgets('unmounting a line of actionable spans does not throw', (
      tester,
    ) async {
      // Disposal itself stays unobservable: GestureRecognizer.dispose only
      // reports to the opt-in leak tracker, and addPointer has no
      // used-after-dispose check, so a widget test cannot distinguish a
      // disposed recognizer from a live one. (The leak tracker was tried --
      // it reports a non-disposed object only once it is garbage collected,
      // which a test cannot force, so it stayed green with disposal removed:
      // a test proving nothing, which is worse than none.)
      //
      // What is checkable is that shrinking the line and then unmounting it
      // raises nothing -- the visible symptom of a double dispose or a use
      // after one.
      const theme = NaturalBlockTheme();

      Future<void> pumpWith(List<TextSpanNode> spans) => tester.pumpWidget(
        MaterialApp(
          home: TextNodeView(
            node: TextNode(children: spans),
            scope: NaturalBlockScope(theme: theme, onTap: (_) {}),
          ),
        ),
      );

      await pumpWith([
        TextSpanNode(text: 'one', decoration: SpanDecoration(isAction: true)),
        TextSpanNode(text: 'two', decoration: SpanDecoration(isAction: true)),
        TextSpanNode(text: 'three', decoration: SpanDecoration(isAction: true)),
      ]);
      expect(tester.takeException(), isNull);

      // Fewer actionable spans than before: the surplus recognizers are
      // released here rather than at unmount.
      await pumpWith([
        TextSpanNode(text: 'one', decoration: SpanDecoration(isAction: true)),
      ]);
      expect(tester.takeException(), isNull);

      await pumpWith([TextSpanNode(text: 'plain')]);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });
  });
}
