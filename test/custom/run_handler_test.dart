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
        reason: 'the image handler declined, so the next one made it tappable',
      );
    });

    testWidgets('a handler may rewrite a run, and one that declines leaves it '
        'to the next', (tester) async {
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
        await tester.pumpWidget(
          MaterialApp(
            home: NaturalBlockView(source: ':@リンク:@', customs: const []),
          ),
        );

        final span = renderedSpans(tester).single;
        expect(
          span.style!.decoration,
          TextDecoration.underline,
          reason: 'the document still says the run is custom',
        );
        expect(span.recognizer, isNull);
        expect(span.semanticsLabel, isNull);
      },
    );

    testWidgets(
      'a widget run answers a tap through Flutter, not a recognizer',
      (tester) async {
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

    testWidgets('the dispose a handler hands back is called, once', (
      tester,
    ) async {
      var released = 0;
      RunRendering? counting(
        String text,
        TextStyle style,
        NaturalBlockTheme theme,
      ) =>
          (span: TextSpan(text: text, style: style), dispose: () => released++);

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
