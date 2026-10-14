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

List<RunHandler> _into(List<String> sink) => [
  (text, style, theme) => tappableText(text, style, onTap: sink.add),
];

void main() {
  TextSpanNode custom(String text) =>
      TextSpanNode(text: text, decoration: SpanDecoration(isCustom: true));

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

    testWidgets('only a run that actually does something is announced', (
      tester,
    ) async {
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
        await pumpRuns(tester, [custom('one'), custom('two'), custom('three')]);
        expect(tester.takeException(), isNull);

        await pumpRuns(tester, [custom('one')]);
        expect(tester.takeException(), isNull);

        await pumpRuns(tester, [TextSpanNode(text: 'plain')]);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.takeException(), isNull);
      });
    });

    testWidgets('a tap interrupted by a rebuild still fires', (tester) async {
      final tapped = <String>[];
      final customs = _into(tapped);

      Future<void> pump() => pumpRuns(
        tester,
        [custom('press')],
        customs: customs,
        ambient: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
      );

      await pump();

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
      await pump(); // rebuild while the pointer is still down
      await gesture.up();
      await tester.pump();

      expect(tapped, [
        'press',
      ], reason: 'the tap must survive a rebuild between down and up');
    });
  });
}
