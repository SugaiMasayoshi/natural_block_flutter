import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

import '../rendered_spans.dart';

void main() {
  group('Selectable text', () {
    testWidgets('a drag selects across cells, rows, a box and a raw block', (
      tester,
    ) async {
      RunRendering? boxed(CustomRun run) =>
          widgetRun(const SizedBox(width: 20, height: 10));

      SelectedContent? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: SelectionArea(
            onSelectionChanged: (content) => selected = content,
            child: NaturalBlockView(
              source: 'a^b|c :@x:@ d\n`raw`\ne',
              // ignore: non_const_argument_for_const_parameter
              customs: [boxed],
            ),
          ),
        ),
      );

      final paragraphs = find.byType(RichText);
      final drag = await tester.startGesture(
        tester.getTopLeft(paragraphs.first) + const Offset(1, 1),
        kind: PointerDeviceKind.mouse,
      );
      await drag.moveTo(
        tester.getBottomRight(paragraphs.last) - const Offset(1, 1),
      );
      await drag.up();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(selected!.plainText.replaceAll(RegExp(r'\s'), ''), 'abcdrawe');
    });
  });

  group('the document is drawn once per source, not once per frame', () {
    testWidgets('a hot reload draws it again', (tester) async {
      // Stands in for handler and builder code a hot reload replaces.
      var drawnAs = 'old';
      RunRendering? handler(CustomRun run) =>
          (span: TextSpan(text: '$drawnAs ${run.text}'), dispose: () {});
      Widget raw(RawNode node, NaturalBlockScope scope) =>
          Text('$drawnAs ${node.text}');

      await tester.pumpWidget(
        MaterialApp(
          home: NaturalBlockView(
            source: ':@x:@|`\nr\n`',
            // ignore: non_const_argument_for_const_parameter
            builders: NaturalBlockBuilders(raw: raw),
            // ignore: non_const_argument_for_const_parameter
            customs: [handler],
          ),
        ),
      );
      expect(renderedSpans(tester).first.text, 'old x');
      expect(find.text('old r'), findsOneWidget);

      drawnAs = 'new';
      tester.binding.buildOwner!.reassemble(tester.binding.rootElement!);
      await tester.pump();

      expect(renderedSpans(tester).first.text, 'new x', reason: 'a handler');
      expect(find.text('new r'), findsOneWidget, reason: 'a builder');
    });

    testWidgets('a handler reading an inherited widget sees it change', (
      tester,
    ) async {
      RunRendering? reads(CustomRun run) => widgetRun(
        Builder(
          builder: (context) =>
              Text('${MediaQuery.sizeOf(context).width.round()}'),
        ),
      );

      final customs = <RunHandler>[reads];
      Widget view(double width) => MediaQuery(
        data: MediaQueryData(size: Size(width, 600)),
        child: MaterialApp(
          // ignore: non_const_argument_for_const_parameter
          home: NaturalBlockView(source: ':@x:@', customs: customs),
        ),
      );

      await tester.pumpWidget(view(300));
      expect(find.text('300'), findsOneWidget);

      await tester.pumpWidget(view(500));
      expect(find.text('500'), findsOneWidget);
    });

    testWidgets('a builder reading an inherited widget sees it change', (
      tester,
    ) async {
      final builders = NaturalBlockBuilders(
        text: (node, scope) => Builder(
          builder: (context) =>
              Text('${MediaQuery.sizeOf(context).width.round()}'),
        ),
      );

      Widget view(double width) => MediaQuery(
        data: MediaQueryData(size: Size(width, 600)),
        child: MaterialApp(
          // ignore: non_const_argument_for_const_parameter
          home: NaturalBlockView(source: 'anything', builders: builders),
        ),
      );

      await tester.pumpWidget(view(300));
      expect(find.text('300'), findsOneWidget);

      await tester.pumpWidget(view(500));
      expect(find.text('500'), findsOneWidget);
    });

    testWidgets('editing one line leaves the other lines as they were', (
      tester,
    ) async {
      var calls = 0;
      RunRendering? counting(CustomRun run) {
        calls++;
        return null;
      }

      final customs = <RunHandler>[counting];

      Widget view(String source) => MaterialApp(
        // ignore: non_const_argument_for_const_parameter
        home: NaturalBlockView(source: source, customs: customs),
      );

      await tester.pumpWidget(view('one :@a:@|two :@b:@'));
      expect(calls, 2, reason: 'both lines built their custom span');

      calls = 0;
      await tester.pumpWidget(view('ONE :@a:@|two :@b:@'));

      expect(calls, 1, reason: 'only the edited line builds its spans again');
    });

    testWidgets('every part of the scope reaches the comparison', (
      tester,
    ) async {
      const inert = <RunHandler>[];
      final wired = <RunHandler>[(run) => tappableText(run, onTap: (_) {})];

      Widget view({
        NaturalBlockTheme? theme,
        NaturalBlockBuilders builders = NaturalBlockBuilders.defaults,
        List<RunHandler>? customs,
      }) => MaterialApp(
        home: NaturalBlockView(
          source: ':@tap:@',
          theme: theme,
          // ignore: non_const_argument_for_const_parameter
          builders: builders,
          // ignore: non_const_argument_for_const_parameter
          customs: customs ?? wired,
        ),
      );

      await tester.pumpWidget(view(customs: inert));
      expect(renderedSpans(tester).single.recognizer, isNull);

      await tester.pumpWidget(view());
      expect(
        renderedSpans(tester).single.recognizer,
        isNotNull,
        reason: 'customs',
      );

      const sized = NaturalBlockTheme(
        custom: TextStyle(color: Color(0xFF123456)),
      );

      await tester.pumpWidget(view(theme: sized));
      expect(
        renderedSpans(tester).single.style!.color,
        const Color(0xFF123456),
        reason: 'theme',
      );

      await tester.pumpWidget(
        view(
          theme: sized,
          builders: NaturalBlockBuilders(
            text: (node, scope) => const Placeholder(),
          ),
        ),
      );
      expect(find.byType(Placeholder), findsOneWidget, reason: 'builders');
    });

    testWidgets('an ancestor rebuild does not re-parse', (tester) async {
      var builds = 0;
      Widget countingText(TextNode node, NaturalBlockScope scope) {
        builds++;
        return const SizedBox.shrink();
      }

      final rebuild = ValueNotifier<int>(0);
      addTearDown(rebuild.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<int>(
            valueListenable: rebuild,
            builder: (context, value, _) => Column(
              children: [
                Text('rebuild $value'),
                NaturalBlockView(
                  source: 'one|two|three',
                  // ignore: non_const_argument_for_const_parameter
                  builders: NaturalBlockBuilders(text: countingText),
                ),
              ],
            ),
          ),
        ),
      );

      expect(builds, 3, reason: 'three blocks on the first build');

      for (var i = 1; i <= 5; i++) {
        rebuild.value = i;
        await tester.pump();
      }

      expect(
        find.text('rebuild 5'),
        findsOneWidget,
        reason: 'the ancestor really did rebuild',
      );
      expect(
        builds,
        3,
        reason:
            'the view hands back the very same tree, so nothing below it is '
            'built again -- not the parse, and not the widgets either',
      );
    });
  });

  group('Tables', () {
    testWidgets('every kind of block renders in an unbounded width', (
      tester,
    ) async {
      for (final source in [
        'plain',
        '|=A|',
        '|>A|',
        '`code here`',
        'a^b',
        '|=~A^B|C^D~',
        '   ',
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: NaturalBlockView(source: source),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull, reason: '"$source"');
      }
    });
  });

  testWidgets('right to left, < is the right edge and > the left', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 400,
              child: NaturalBlockView(source: '|<A|>B|'),
            ),
          ),
        ),
      ),
    );

    Rect rectOf(String text) =>
        tester.getRect(find.text(text, findRichText: true));

    expect(rectOf('A').right, closeTo(400, 1));
    expect(rectOf('B').left, closeTo(0, 1));
  });
}
