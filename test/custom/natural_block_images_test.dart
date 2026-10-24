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

  Future<void> pumpImages(
    WidgetTester tester,
    String source, {
    NaturalBlockTheme theme = const NaturalBlockTheme(),
  }) => tester.pumpWidget(
    wrap(
      NaturalBlockView(
        source: source,
        theme: theme,
        customs: const [NaturalBlockImages.network],
      ),
    ),
  );

  test('sourceOf reads image(...) and declines anything else', () {
    const expected = <String, String?>{
      'image(https://example.invalid/a.png)': 'https://example.invalid/a.png',
      'image(https://example.invalid/x.png?id=you&v=2)':
          'https://example.invalid/x.png?id=you&v=2',
      'image(https://example.invalid/a_(1).png)':
          'https://example.invalid/a_(1).png',
      'img(https://example.invalid/a.png)': null,
      'image( https://example.invalid/a.png )': null,
      'image(https://example.invalid/a.png) ': null,
      'image()': null,
    };

    for (final MapEntry(key: text, value: source) in expected.entries) {
      expect(NaturalBlockImages.sourceOf(text), source, reason: '"$text"');
    }
  });

  test('kindOf classifies where a payload points', () {
    const expected = <ImageSourceKind, List<String>>{
      ImageSourceKind.network: [
        'https://example.invalid/a.png',
        'http://example.invalid/a.png',
        'https://example.invalid/x.png?id=you',
      ],
      ImageSourceKind.file: [
        r'C:\Users\sugai\a.png',
        'C:/Users/sugai/a.png',
        r'D:\photos\My Pictures\a.png',
        r'c:\lower\a.png',
        r'\\server\share\a.png',
        '/home/sugai/a.png',
        'file:///C:/Users/a.png',
      ],
      ImageSourceKind.relative: ['./assets/a.png', 'assets/a.png', 'a.png', ''],
    };

    for (final MapEntry(key: kind, value: sources) in expected.entries) {
      for (final source in sources) {
        expect(
          NaturalBlockImages.kindOf(source),
          kind,
          reason: '"$source" is $kind',
        );
      }
    }
  });

  group('Images', () {
    testWidgets('an image payload becomes a WidgetSpan, not text', (
      tester,
    ) async {
      await pumpImages(tester, ':@image(https://example.invalid/a.png):@');

      final richText = tester.widget<RichText>(find.byType(RichText));
      final child = (richText.text as TextSpan).children!.single as TextSpan;

      expect(
        child.children!.single,
        isA<WidgetSpan>(),
        reason: 'the run renders as a widget rather than as its text',
      );
      expect(
        (child.children!.single as WidgetSpan).alignment,
        PlaceholderAlignment.middle,
        reason:
            'not `WidgetSpan`\'s own default of bottom, which leaves the '
            'text beside it hanging below the image',
      );
    });

    test('the scale follows only the steps', () {
      double scaleWith(SpanDecoration decoration) => NaturalBlockImages.scaleOf(
        CustomRun(
          text: 'image(https://example.invalid/a.png)',
          style: const TextStyle(fontSize: 30),
          theme: const NaturalBlockTheme(baseFontSize: 14, fontSizeStep: 4),
          decoration: decoration,
          withContext: (_) {},
        ),
      );

      expect(scaleWith(const SpanDecoration()), 1);
      expect(scaleWith(SpanDecoration(sizeOffset: 1)), 14 / 18);
    });

    testWidgets('an image carries a semantic label', (tester) async {
      await pumpImages(tester, ':@image(https://example.invalid/a.png):@');

      expect(
        tester.widget<Image>(find.byType(Image)).semanticLabel,
        'https://example.invalid/a.png',
      );
    });

    testWidgets('network declines a local path rather than fetching it', (
      tester,
    ) async {
      await pumpImages(tester, ':@image(C:/a.png):@');

      expect(find.byType(Image), findsNothing);
      expect(renderedSpans(tester).single.text, 'image(C:/a.png)');
    });

    testWidgets('an image that cannot be drawn falls back to its payload', (
      tester,
    ) async {
      for (final (payload, handler) in [
        ('image(https://example.invalid/a.png)', NaturalBlockImages.network),
        ('image(C:/no/such/file.png)', NaturalBlockImages.local),
      ]) {
        await tester.pumpWidget(
          // ignore: non_const_argument_for_const_parameter
          wrap(NaturalBlockView(source: ':@$payload:@', customs: [handler])),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pump();

        expect(
          find.descendant(
            of: find.byType(Image),
            matching: find.text(payload, findRichText: true),
          ),
          findsOneWidget,
          reason: 'the image was tried, and its error shows the payload',
        );
      }
    });

    testWidgets('NaturalBlockImages.local draws a local path from a file', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: r':@image(C:\a.png):@',
            theme: NaturalBlockTheme(baseFontSize: 28),
            customs: [NaturalBlockImages.local, NaturalBlockImages.network],
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as FileImage).scale, 1);
      expect(image.semanticLabel, r'C:\a.png');
    });

    testWidgets('NaturalBlockImages.local still draws a network image', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: ':@image(https://example.invalid/a.png):@',
            customs: [NaturalBlockImages.local, NaturalBlockImages.network],
          ),
        ),
      );

      expect(
        tester.widget<Image>(find.byType(Image)).image,
        isA<NetworkImage>(),
      );
    });

    testWidgets(
      'NaturalBlockImages.local declines a file URI it cannot turn into a '
      'path, rather than throwing',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            const NaturalBlockView(
              source: ':@image(file:///a.png?v=1):@',
              customs: [NaturalBlockImages.local, NaturalBlockImages.network],
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(Image), findsNothing);
        expect(renderedSpans(tester).single.text, 'image(file:///a.png?v=1)');
      },
    );

    testWidgets('NaturalBlockImages.local leaves a relative path to the app', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: ':@image(assets/a.png):@',
            customs: [NaturalBlockImages.local, NaturalBlockImages.network],
          ),
        ),
      );

      expect(find.byType(Image), findsNothing);
      expect(renderedSpans(tester).single.text, 'image(assets/a.png)');
    });
  });
}
