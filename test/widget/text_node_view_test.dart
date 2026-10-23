import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

import '../rendered_spans.dart';

RunRendering? _plain(CustomRun run) =>
    (span: TextSpan(text: run.text, style: run.style), dispose: () {});

RunRendering? _plainElsewhere(CustomRun run) =>
    (span: TextSpan(text: run.text, style: run.style), dispose: () {});

void main() {
  TextSpanNode custom(String text) =>
      TextSpanNode(text: text, decoration: SpanDecoration(isCustom: true));

  Future<void> pumpRuns(
    WidgetTester tester,
    List<InlineNode> runs, {
    NaturalBlockTheme theme = const NaturalBlockTheme(),
    List<RunHandler> customs = const [],
    TextStyle? ambient,
  }) {
    final view = TextNodeView(
      node: TextNode(children: runs),
      scope: NaturalBlockScope(theme: theme, customs: customs),
    );
    return tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: ambient == null
              ? view
              : DefaultTextStyle(style: ambient, child: view),
        ),
      ),
    );
  }

  TextSpan onlySpan(WidgetTester tester) => renderedSpans(tester).single;

  group('when the spans are rebuilt', () {
    testWidgets('a rebuild with the same runs keeps them', (tester) async {
      await pumpRuns(tester, [TextSpanNode(text: 'x')]);
      final first = onlySpan(tester);

      await pumpRuns(tester, [TextSpanNode(text: 'x')]);

      expect(onlySpan(tester), same(first));
    });

    testWidgets('an ambient change the spans do not see keeps them', (
      tester,
    ) async {
      const theme = NaturalBlockTheme(base: TextStyle(fontSize: 20));

      await pumpRuns(
        tester,
        [TextSpanNode(text: 'x')],
        theme: theme,
        ambient: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
      );
      final first = onlySpan(tester);

      await pumpRuns(
        tester,
        [TextSpanNode(text: 'x')],
        theme: theme,
        ambient: const TextStyle(fontSize: 30, color: Color(0xFF000000)),
      );

      expect(onlySpan(tester), same(first));
    });

    testWidgets('a different handler rebuilds them', (tester) async {
      await pumpRuns(tester, [custom('x')], customs: const [_plain]);
      final first = onlySpan(tester);

      await pumpRuns(tester, [custom('x')], customs: const [_plainElsewhere]);

      expect(onlySpan(tester), isNot(same(first)));
    });

    testWidgets('changed runs rebuild them', (tester) async {
      await pumpRuns(tester, [TextSpanNode(text: 'x')]);
      final first = onlySpan(tester);

      await pumpRuns(tester, [TextSpanNode(text: 'y')]);

      expect(onlySpan(tester), isNot(same(first)));
    });

    testWidgets('a changed theme rebuilds them', (tester) async {
      await pumpRuns(tester, [TextSpanNode(text: 'x')]);
      final first = onlySpan(tester);

      await pumpRuns(tester, [
        TextSpanNode(text: 'x'),
      ], theme: const NaturalBlockTheme(fontSizeStep: 9));

      expect(onlySpan(tester), isNot(same(first)));
    });

    testWidgets('a changed ambient text style rebuilds them', (tester) async {
      await pumpRuns(tester, [
        TextSpanNode(text: 'x'),
      ], ambient: const TextStyle(fontSize: 14));
      final first = onlySpan(tester);

      await pumpRuns(tester, [
        TextSpanNode(text: 'x'),
      ], ambient: const TextStyle(fontSize: 22));

      expect(onlySpan(tester), isNot(same(first)));
    });
  });

  testWidgets('a raw run takes its size from the same root as its neighbours', (
    tester,
  ) async {
    await pumpRuns(
      tester,
      [TextSpanNode(text: 'a'), RawSpanNode(text: 'code')],
      theme: const NaturalBlockTheme(base: TextStyle(fontSize: 20)),
      ambient: const TextStyle(fontSize: 30),
    );

    final spans = renderedSpans(tester);
    expect(spans[0].style!.fontSize, 20);
    expect(spans[1].style!.fontSize, 20);
    expect(spans[1].style!.fontFamily, 'monospace');
  });

  testWidgets('a tap interrupted by a rebuild still fires', (tester) async {
    final tapped = <String>[];
    final customs = <RunHandler>[
      (run) => tappableText(run.text, run.style, onTap: tapped.add),
    ];

    Future<void> pump() =>
        pumpRuns(tester, [custom('press')], customs: customs);

    await pump();

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(RichText)),
    );
    await pump(); // rebuild while the pointer is still down
    await gesture.up();
    await tester.pump();

    expect(tapped, [
      'press',
    ], reason: 'the tap must survive a rebuild between down and up');
  });
}
