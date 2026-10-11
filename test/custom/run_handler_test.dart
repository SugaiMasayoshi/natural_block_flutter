import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

import '../rendered_spans.dart';

RunRendering? _mentions(
  String text,
  TextStyle style,
  NaturalBlockTheme theme,
) => text.startsWith('user(') && text.endsWith(')')
    ? (
        span: TextSpan(text: text.substring(5, text.length - 1), style: style),
        dispose: () {},
      )
    : null;

RunHandler _tappableBox(List<String> sink) =>
    (text, style, theme) => widgetRun(
      GestureDetector(
        // An empty box defers its hit testing to a child it does not have.
        behavior: HitTestBehavior.opaque,
        onTap: () => sink.add(text),
        child: const SizedBox(width: 20, height: 20),
      ),
    );

void _ignore(String _) {}

RunRendering? _links(String text, TextStyle style, NaturalBlockTheme theme) =>
    tappableText(text, style, onTap: _ignore);

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: DefaultTextStyle(
      style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
      child: child,
    ),
  );

  group('run handlers', () {
    testWidgets('declining leaves the run as ordinary custom text', (
      tester,
    ) async {
      // The property that makes the extension point safe: a builder never
      // has to understand every payload it meets, and one it does not
      // understand still reads as text rather than disappearing.
      await tester.pumpWidget(
        wrap(
          NaturalBlockView(
            source: ':@#section:@',
            customs: [NaturalBlockImages.network, _links],
          ),
        ),
      );

      final span = renderedSpans(tester).single;
      expect(span.text, '#section');
      expect(
        span.recognizer,
        isNotNull,
        reason: 'a declined run keeps the default tap handling',
      );
    });

    testWidgets('a handler that declines leaves the run to the next', (
      tester,
    ) async {
      // What replaced "falling back": a handler of your own does not call
      // this package's, it just sits in front of it and declines what is not
      // its own.
      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: ':@user(alice):@ and :@image(https://example.com/a.png):@',
            customs: [_mentions, NaturalBlockImages.network],
          ),
        ),
      );

      expect(renderedSpans(tester).first.text, 'alice');
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets(
      'with no tapping handler a run keeps its style and drops the tap',
      (tester) async {
        // Tapping is a handler like any other, so an app that includes none
        // gets none.
        await tester.pumpWidget(
          MaterialApp(
            home: NaturalBlockView(source: ':@リンク:@', customs: const []),
          ),
        );

        final span = renderedSpans(tester).single;
        expect(
          span.style!.decoration,
          TextDecoration.underline,
          reason: 'the document still says the run is actionable',
        );
        expect(span.recognizer, isNull);
        expect(span.semanticsLabel, isNull);
      },
    );

    testWidgets(
      'a widget run answers a tap through Flutter, not a recognizer',
      (tester) async {
        // What makes replacement and tappability independent: anything inside
        // a WidgetSpan is Flutter's to manage, so this handler releases
        // nothing.
        final tapped = <String>[];
        await tester.pumpWidget(
          MaterialApp(
            home: Align(
              alignment: Alignment.topLeft,
              child: NaturalBlockView(
                source: ':@box:@',
                customs: [_tappableBox(tapped)],
              ),
            ),
          ),
        );

        await tester.tap(find.byType(GestureDetector));
        await tester.pump();

        expect(tapped, ['box']);
        expect(renderedSpans(tester), isEmpty, reason: 'drawn as a widget');
      },
    );

    testWidgets('when two handlers claim a run, the first draws it', (
      tester,
    ) async {
      var asked = 0;
      RunRendering? second(String text, TextStyle style, NaturalBlockTheme _) {
        asked++;
        return (span: TextSpan(text: 'second'), dispose: () {});
      }

      RunRendering? first(String text, TextStyle style, NaturalBlockTheme _) =>
          (span: TextSpan(text: 'first'), dispose: () {});

      await tester.pumpWidget(
        MaterialApp(
          home: NaturalBlockView(source: ':@x:@', customs: [first, second]),
        ),
      );

      expect(renderedSpans(tester).single.text, 'first');
      expect(asked, 0, reason: 'the second is not asked once the first claims');
    });

    testWidgets('a text run may rewrite what is read', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NaturalBlockView(
            source: ':@user(alice):@',
            customs: const [_mentions],
          ),
        ),
      );

      expect(renderedSpans(tester).single.text, 'alice');
    });

    testWidgets('the dispose a handler hands back is called, once', (
      tester,
    ) async {
      // The whole of the contract: whatever a handler makes, the `dispose` it
      // returns is the only thing that releases it. Called when the line's
      // spans are replaced, and when the line leaves the tree -- and not
      // twice for the same span.
      var released = 0;
      RunRendering? counting(
        String text,
        TextStyle style,
        NaturalBlockTheme theme,
      ) =>
          (span: TextSpan(text: text, style: style), dispose: () => released++);

      // Held outside `view`, the way the docs ask: a list written afresh on
      // every build never compares equal, and the spans would be replaced on
      // every frame.
      final customs = <RunHandler>[counting];
      Widget view(String source) => MaterialApp(
        home: NaturalBlockView(source: source, customs: customs),
      );

      await tester.pumpWidget(view('one :@x:@'));
      expect(released, 0);

      await tester.pumpWidget(view('one :@x:@'));
      expect(released, 0, reason: 'nothing it was built from changed');

      await tester.pumpWidget(view('two :@x:@'));
      expect(released, 1, reason: 'the line was rebuilt, so the span went');

      await tester.pumpWidget(const SizedBox.shrink());
      expect(released, 2, reason: 'the line left the tree');
      expect(tester.takeException(), isNull);
    });
  });
}
