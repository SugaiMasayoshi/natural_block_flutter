import 'dart:io';
import 'dart:ui' as ui;

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

    testWidgets('a step scales the image from the size its space leaves it', (
      tester,
    ) async {
      final folder = Directory.systemTemp.createTempSync('natural_block_');
      final file = File('${folder.path}/200x100.png');
      await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        Canvas(recorder).drawColor(const Color(0xFF336699), BlendMode.src);
        final image = await recorder.endRecording().toImage(200, 100);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await file.writeAsBytes(png!.buffer.asUint8List());
      });
      addTearDown(() => folder.deleteSync(recursive: true));

      Future<Size> drawnAt(String steps, {required double width}) async {
        await tester.pumpWidget(
          wrap(
            Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: NaturalBlockView(
                  source: ':$steps@image(${file.path}):@',
                  customs: const [NaturalBlockImages.local],
                ),
              ),
            ),
          ),
        );
        for (var tries = 0; tries < 20; tries++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 50)),
          );
          await tester.pump();
          if (tester.getSize(find.byType(Image)) != Size.zero) break;
        }
        return tester.getSize(find.byType(Image));
      }

      expect(await drawnAt('', width: 1000), const Size(200, 100));
      expect(await drawnAt('+', width: 1000), const Size(240, 120));
      expect(await drawnAt('', width: 100), const Size(100, 50));
      expect(
        await drawnAt('-', width: 100),
        const Size(100 / 1.2, 50 / 1.2),
        reason: 'the step shows on an image its space already shrank',
      );
      expect(await drawnAt('++++', width: 100), const Size(100, 50));
    });

    testWidgets('an image carries a semantic label', (tester) async {
      await pumpImages(tester, ':@image(https://example.invalid/a.png):@');

      expect(
        tester.widget<Image>(find.byType(Image)).semanticLabel,
        'https://example.invalid/a.png',
      );
    });

    testWidgets('networkImage gives the image network draws, as a widget', (
      tester,
    ) async {
      final image = NaturalBlockImages.networkImage(
        CustomRun(
          text: 'image(https://example.invalid/a.png)',
          style: const TextStyle(fontSize: 30),
          theme: const NaturalBlockTheme(),
          decoration: const SpanDecoration(),
          withContext: (_) {},
        ),
      );
      await tester.pumpWidget(wrap(image!));

      expect(find.byType(Image), findsOneWidget);
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

    test('localImage reads the path an app resolved a relative one to', () {
      final run = CustomRun(
        text: 'image(a.png)',
        style: const TextStyle(fontSize: 30),
        theme: const NaturalBlockTheme(),
        decoration: const SpanDecoration(),
        withContext: (_) {},
      );

      expect(NaturalBlockImages.localImage(run), isNull);
      expect(
        NaturalBlockImages.localImage(run, path: 'C:/talk/a.png'),
        isNotNull,
      );
    });
  });
}
