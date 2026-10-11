import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

import '../rendered_spans.dart';

void _ignore(String _) {}

RunRendering? _wired(String text, TextStyle style, NaturalBlockTheme theme) =>
    tappableText(text, style, onTap: _ignore);

RunRendering? _wiredElsewhere(
  String text,
  TextStyle style,
  NaturalBlockTheme theme,
) => tappableText(text, style, onTap: _ignore);

/// Handlers that report each tap into [sink]. Built once per test: a list
/// written afresh is a different list, and a different list redraws.
List<RunHandler> _into(List<String> sink) => [
  (text, style, theme) => tappableText(text, style, onTap: sink.add),
];

void main() {
  TextSpanNode custom(String text) =>
      TextSpanNode(text: text, decoration: SpanDecoration(isCustom: true));

  /// Draws [runs] as one line. By default something is wired to every
  /// custom run; `const []` is an app that wired nothing, which is the
  /// difference between a custom run and a tappable one.
  Future<void> pumpRuns(
    WidgetTester tester,
    List<InlineNode> runs, {
    NaturalBlockTheme theme = const NaturalBlockTheme(),
    List<RunHandler> customs = const [_wired],
    TextStyle? ambient,
  }) {
    final view = TextNodeView(
      node: TextNode(children: runs),
      scope: NaturalBlockScope(theme: theme, customs: customs),
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

  group('styles', () {
    testWidgets('every run is drawn with styleFor on its own decoration', (
      tester,
    ) async {
      // All this layer owes: each run's decoration goes to the theme and the
      // answer lands on that run's span, in that run's place. What any one
      // decoration is worth -- how tones, emphasis, custom marking and the
      // size steps compose -- is `styleFor`'s own business, tested there
      // without pumping anything.
      const theme = NaturalBlockTheme();
      const ambientSize = 14.0;
      const decorations = [
        SpanDecoration(),
        SpanDecoration(tone: Tone.negative),
        SpanDecoration(tone: Tone.negative, emphasis: true, isCustom: true),
        SpanDecoration(sizeOffset: 2),
        SpanDecoration(sizeOffset: -99),
      ];

      await pumpRuns(
        tester,
        [
          for (var i = 0; i < decorations.length; i++)
            TextSpanNode(text: 'run $i', decoration: decorations[i]),
        ],
        theme: theme,
        customs: const [],
        ambient: const TextStyle(fontSize: ambientSize),
      );

      expect(tester.takeException(), isNull);

      final spans = renderedSpans(tester);
      for (var i = 0; i < decorations.length; i++) {
        expect(spans[i].text, 'run $i');
        expect(
          spans[i].style,
          theme.styleFor(decorations[i], baseSize: ambientSize),
        );
      }
    });

    testWidgets('a size step counts from the size the theme actually draws, '
        'not from the ambient one', (tester) async {
      // The README's first theme example is `base: TextStyle(fontSize: 16)`,
      // and `theme.base` wins over the ambient `DefaultTextStyle` for the
      // root span. A sized run has to count from the same place, or `:+`
      // renders *smaller* than the text beside it.
      const theme = NaturalBlockTheme(base: TextStyle(fontSize: 24));

      await pumpRuns(
        tester,
        [
          TextSpanNode(text: 'plain'),
          TextSpanNode(
            text: 'bigger',
            decoration: SpanDecoration(sizeOffset: 1),
          ),
        ],
        theme: theme,
        ambient: const TextStyle(fontSize: 14),
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
  });

  group('custom spans', () {
    testWidgets('a recognizer appears for a custom run, and only when '
        'something is wired to it', (tester) async {
      await pumpRuns(tester, [custom('tap me')]);
      expect(recognizerOf(tester), isA<TapGestureRecognizer>());

      await pumpRuns(tester, [custom('tap me')], customs: const []);
      expect(recognizerOf(tester), isNull, reason: 'nothing wired');

      await pumpRuns(tester, [TextSpanNode(text: 'plain')]);
      expect(recognizerOf(tester), isNull, reason: 'not custom');
    });

    testWidgets("a tap calls onTap with exactly that run's text", (
      tester,
    ) async {
      final tapped = <String>[];
      await pumpRuns(tester, [
        custom('actionable'),
        TextSpanNode(text: ' plain'),
      ], customs: _into(tapped));

      (recognizerOf(tester)! as TapGestureRecognizer).onTap!();

      expect(tapped, ['actionable']);
    });

    testWidgets('tapping a non-custom run does not fire onTap', (tester) async {
      final tapped = <String>[];
      await pumpRuns(tester, [
        custom('actionable'),
        TextSpanNode(text: ' plain'),
      ], customs: _into(tapped));

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
      // Style follows the document -- it said the run is custom, so it
      // renders as such either way. Semantics follow what will actually
      // happen: telling a screen reader a run is interactive when no
      // handler is wired is a promise nothing keeps.
      const theme = NaturalBlockTheme();

      await pumpRuns(tester, [custom('tap me')], customs: const []);
      final inert = renderedSpans(tester).single;
      expect(inert.style!.decoration, theme.custom.decoration);
      expect(
        inert.semanticsLabel,
        isNull,
        reason: 'no handler, so nothing is announced as interactive',
      );

      await pumpRuns(tester, [custom('tap me')]);
      expect(renderedSpans(tester).single.semanticsLabel, 'tap me');
    });

    group('the spans, and the recognizers they carry', () {
      // The property the whole design turns on. A recognizer that has taken
      // a pointer down owns an entry in the gesture arena; replacing it
      // mid-gesture throws that entry away. The spans are built outside
      // `build` so that the recognizers survive a rebuild -- see the
      // interrupted-tap test below.
      testWidgets('a rebuild with the same runs keeps the recognizer', (
        tester,
      ) async {
        await pumpRuns(tester, [custom('tap me')]);
        final first = recognizerOf(tester);

        await pumpRuns(tester, [custom('tap me')]);

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
          [custom('tap me')],
          theme: theme,
          ambient: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
        );
        final first = recognizerOf(tester);

        await pumpRuns(
          tester,
          [custom('tap me')],
          theme: theme,
          ambient: const TextStyle(fontSize: 30, color: Color(0xFF000000)),
        );

        expect(recognizerOf(tester), same(first));
      });

      testWidgets('the same handlers are not a reason to rebuild', (
        tester,
      ) async {
        // A handler is compared by identity, so a caller who keeps theirs
        // stable -- a top-level function, or a method of their state --
        // keeps the recognizers too.
        await pumpRuns(tester, [custom('tap me')], customs: const [_wired]);
        final first = recognizerOf(tester);

        await pumpRuns(tester, [custom('tap me')], customs: const [_wired]);

        expect(recognizerOf(tester), same(first));
      });

      testWidgets('a different handler rebuilds the spans', (tester) async {
        await pumpRuns(tester, [custom('tap me')], customs: const [_wired]);
        final first = recognizerOf(tester);

        await pumpRuns(
          tester,
          [custom('tap me')],
          customs: const [_wiredElsewhere],
        );

        expect(recognizerOf(tester), isNot(same(first)));
      });

      testWidgets('changed runs rebuild the spans', (tester) async {
        // The accepted cost: a tap held across an edit to this line is lost.
        await pumpRuns(tester, [custom('tap me')]);
        final first = recognizerOf(tester);

        await pumpRuns(tester, [custom('tap again')]);

        expect(recognizerOf(tester), isNot(same(first)));
      });

      testWidgets('a changed theme rebuilds the spans', (tester) async {
        await pumpRuns(tester, [custom('tap me')]);
        final first = recognizerOf(tester);

        await pumpRuns(tester, [
          custom('tap me'),
        ], theme: const NaturalBlockTheme(fontSizeStep: 9));

        expect(recognizerOf(tester), isNot(same(first)));
      });

      testWidgets('a raw run is drawn from the same root as its neighbours', (
        tester,
      ) async {
        // Both used to read the ambient style for themselves, which put what
        // they read outside what they are compared by: a `base` that names a
        // size makes `rootStyle` identical across an ambient size change, so
        // the spans were kept while a raw run, reading the ambient size
        // directly, had every reason to have moved. It showed the old size
        // for as long as the line was not rebuilt for some other reason.
        const theme = NaturalBlockTheme(base: TextStyle(fontSize: 20));

        Future<void> pump(double ambient) => pumpRuns(
          tester,
          [TextSpanNode(text: 'a'), RawSpanNode(text: 'code')],
          theme: theme,
          ambient: TextStyle(fontSize: ambient),
        );

        await pump(14);
        var spans = renderedSpans(tester);
        expect(spans[1].style!.fontSize, spans[0].style!.fontSize);

        await pump(30);
        spans = renderedSpans(tester);
        expect(
          spans[1].style!.fontSize,
          spans[0].style!.fontSize,
          reason: 'the raw run moves with the line or not at all',
        );
        expect(spans[1].style!.fontFamily, theme.raw.fontFamily);
      });

      testWidgets('a changed ambient text style rebuilds the spans', (
        tester,
      ) async {
        // Reached through didChangeDependencies rather than didUpdateWidget:
        // `DefaultTextStyle` decides what every run starts from and can
        // change without any of this widget's own fields changing.
        await pumpRuns(tester, [
          custom('tap me'),
        ], ambient: const TextStyle(fontSize: 14));
        final first = recognizerOf(tester);

        await pumpRuns(tester, [
          custom('tap me'),
        ], ambient: const TextStyle(fontSize: 22));

        expect(recognizerOf(tester), isNot(same(first)));
      });

      testWidgets('shrinking a line and then unmounting it does not throw', (
        tester,
      ) async {
        // Disposal itself stays unobservable: GestureRecognizer.dispose only
        // reports to the opt-in leak tracker, and addPointer has no
        // used-after-dispose check, so a widget test cannot distinguish a
        // disposed recognizer from a live one. (The leak tracker was tried --
        // it reports a non-disposed object only once it is garbage collected,
        // which a test cannot force, so it stayed green with disposal
        // removed: a test proving nothing, which is worse than none.)
        //
        // What is checkable is that releasing recognizers raises nothing, in
        // both of the places it happens -- replacing the spans, and
        // unmounting the view. Disposing one twice throws, so the second
        // must find nothing left.
        await pumpRuns(tester, [custom('one'), custom('two'), custom('three')]);
        expect(tester.takeException(), isNull);

        // Fewer custom runs than before: the surplus recognizers are
        // released here rather than at unmount.
        await pumpRuns(tester, [custom('one')]);
        expect(tester.takeException(), isNull);

        await pumpRuns(tester, [TextSpanNode(text: 'plain')]);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.takeException(), isNull);
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
      final customs = _into(tapped);

      // A different theme instance each time, so the rebuild is real work
      // rather than an identical widget Flutter can skip.
      Future<void> pump(String suffix) => pumpRuns(
        tester,
        [custom('press')],
        theme: NaturalBlockTheme(
          base: TextStyle(letterSpacing: suffix.length * 0.0),
        ),
        customs: customs,
        ambient: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
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
  });
}
