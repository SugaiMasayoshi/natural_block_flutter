import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

import '../rendered_spans.dart';

RunRendering? _boxed(String text, TextStyle style, NaturalBlockTheme theme) =>
    widgetRun(const SizedBox(width: 20, height: 10));

void _ignore(String _) {}

RunRendering? _links(String text, TextStyle style, NaturalBlockTheme theme) =>
    tappableText(text, style, onTap: _ignore);

void main() {
  group('Selectable text', () {
    testWidgets('a drag selects across cells, rows, a box and a raw block', (
      tester,
    ) async {
      SelectedContent? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: SelectionArea(
            onSelectionChanged: (content) => selected = content,
            child: const NaturalBlockView(
              source: 'a^b|c :@x:@ d\n`raw`\ne',
              customs: [_boxed],
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
    ({NaturalBlockBuilders builders, List<int> builds}) counting() {
      final builds = <int>[];
      return (
        builds: builds,
        builders: NaturalBlockBuilders(
          text: (node, scope) {
            builds.add(1);
            return const SizedBox.shrink();
          },
        ),
      );
    }

    testWidgets('a handler reading an inherited widget sees it change', (
      tester,
    ) async {
      RunRendering? reads(
        String text,
        TextStyle style,
        NaturalBlockTheme theme,
      ) => widgetRun(
        Builder(
          builder: (context) =>
              Text('${MediaQuery.sizeOf(context).width.round()}'),
        ),
      );

      final customs = <RunHandler>[reads];
      Widget view(double width) => MediaQuery(
        data: MediaQueryData(size: Size(width, 600)),
        child: MaterialApp(
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
      RunRendering? counting(
        String text,
        TextStyle style,
        NaturalBlockTheme theme,
      ) {
        calls++;
        return null;
      }

      final customs = <RunHandler>[counting];

      Widget view(String source) => MaterialApp(
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
      const wired = <RunHandler>[_links];

      Widget view({
        NaturalBlockTheme? theme,
        NaturalBlockBuilders builders = NaturalBlockBuilders.defaults,
        List<RunHandler> customs = wired,
      }) => MaterialApp(
        home: NaturalBlockView(
          source: ':@tap:@',
          theme: theme,
          builders: builders,
          customs: customs,
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

      const sized = NaturalBlockTheme(custom: TextStyle(fontSize: 33));

      await tester.pumpWidget(view(theme: sized));
      expect(renderedSpans(tester).single.style!.fontSize, 33, reason: 'theme');

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
      final counter = counting();
      final rebuild = ValueNotifier<int>(0);
      addTearDown(rebuild.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<int>(
            valueListenable: rebuild,
            builder: (context, value, _) => Padding(
              padding: EdgeInsets.all(value.toDouble()),
              child: NaturalBlockView(
                source: 'one|two|three',
                builders: counter.builders,
              ),
            ),
          ),
        ),
      );

      final afterFirst = counter.builds.length;
      expect(afterFirst, 3, reason: 'three blocks on the first build');

      for (var i = 1; i <= 5; i++) {
        rebuild.value = i;
        await tester.pump();
      }

      expect(
        tester.widget<Padding>(find.byType(Padding).first).padding,
        const EdgeInsets.all(5),
        reason: 'the ancestor really did rebuild',
      );
      expect(
        counter.builds.length,
        afterFirst,
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
}
