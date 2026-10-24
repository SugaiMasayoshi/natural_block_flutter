import 'package:flutter/gestures.dart';
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

  group('tappableText', () {
    testWidgets('makes only the custom run tappable, and reports its text', (
      tester,
    ) async {
      final tapped = <String>[];
      await tester.pumpWidget(
        wrap(
          NaturalBlockView(
            source: ':@tap me:@ plain',
            customs: [
              (run) => tappableText(run.text, run.style, onTap: tapped.add),
            ],
          ),
        ),
      );

      final spans = renderedSpans(tester);
      expect(spans.last.recognizer, isNull, reason: 'not custom');
      expect(spans.first.semanticsLabel, 'tap me');

      (spans.first.recognizer! as TapGestureRecognizer).onTap!();
      expect(tapped, ['tap me']);
    });

    testWidgets('with no handler a custom run is neither tappable nor '
        'announced', (tester) async {
      await tester.pumpWidget(
        wrap(const NaturalBlockView(source: ':@tap me:@')),
      );

      final span = renderedSpans(tester).single;
      expect(span.style!.decoration, TextDecoration.underline);
      expect(span.recognizer, isNull);
      expect(span.semanticsLabel, isNull);
    });
  });

  group('Drawing a custom run yourself', () {
    testWidgets('a handler may rewrite a run, and one that declines leaves it '
        'to the next', (tester) async {
      RunRendering? mentions(CustomRun run) =>
          run.text.startsWith('user(') && run.text.endsWith(')')
          ? (
              span: TextSpan(
                text: run.text.substring(5, run.text.length - 1),
                style: run.style,
              ),
              dispose: () {},
            )
          : null;

      await tester.pumpWidget(
        wrap(
          NaturalBlockView(
            source:
                ':@user(alice):@ and :@image(https://example.invalid/a.png):@',
            customs: [mentions, NaturalBlockImages.network],
          ),
        ),
      );

      expect(renderedSpans(tester).first.text, 'alice');
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('when two handlers claim a run, the first draws it', (
      tester,
    ) async {
      var asked = 0;
      RunRendering? second(CustomRun run) {
        asked++;
        return (span: TextSpan(text: 'second'), dispose: () {});
      }

      RunRendering? first(CustomRun run) =>
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
      RunRendering? counting(CustomRun run) => (
        span: TextSpan(text: run.text, style: run.style),
        dispose: () => released++,
      );

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
