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

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: DefaultTextStyle(
      style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
      child: child,
    ),
  );

  group('run handlers', () {
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
