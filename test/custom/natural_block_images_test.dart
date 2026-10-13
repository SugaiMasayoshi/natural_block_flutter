import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

import '../rendered_spans.dart';

RunRendering? _localStandIn(
  String text,
  TextStyle style,
  NaturalBlockTheme theme,
) {
  final source = NaturalBlockImages.sourceOf(text);
  if (source == null ||
      NaturalBlockImages.kindOf(source) != ImageSourceKind.file) {
    return null;
  }
  return widgetRun(Text('local:$source'));
}

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

  Future<void> pumpImages(
    WidgetTester tester,
    String source, {
    NaturalBlockTheme theme = const NaturalBlockTheme(),
    List<RunHandler> customs = const [NaturalBlockImages.network, _links],
  }) => tester.pumpWidget(
    wrap(NaturalBlockView(source: source, theme: theme, customs: customs)),
  );

  group('the image(...) convention', () {
    test('a payload that names an image yields its source', () {
      expect(
        NaturalBlockImages.sourceOf('image(https://example.com/a.png)'),
        'https://example.com/a.png',
      );
    });

    test('a URL keeps its query string and any parentheses in the path', () {
      expect(
        NaturalBlockImages.sourceOf('image(https://e.com/x.png?id=you&v=2)'),
        'https://e.com/x.png?id=you&v=2',
      );
      expect(
        NaturalBlockImages.sourceOf('image(https://e.com/a_(1).png)'),
        'https://e.com/a_(1).png',
      );
    });

    test('anything else is declined, `img` included', () {
      for (final text in [
        'https://example.com',
        '#section',
        'image()',
        ' image(https://e.com/a.png)',
        'image(https://e.com/a.png) ',
        'image( https://e.com/a.png)',
        'image(https://e.com/a.png )',
        'img(https://e.com/a.png)',
        'IMAGE(https://e.com/a.png)',
        'image(https://e.com/a.png) trailing',
        '',
      ]) {
        expect(
          NaturalBlockImages.sourceOf(text),
          isNull,
          reason: '"$text" is not the image(...) convention',
        );
      }
    });
  });

  test('kindOf classifies where a payload points', () {
    const expected = <ImageSourceKind, List<String>>{
      ImageSourceKind.network: [
        'https://example.com/a.png',
        'http://example.com/a.png',
        'https://e.com/x.png?id=you',
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

  group('as a run handler', () {
    testWidgets('an image payload becomes a WidgetSpan, not text', (
      tester,
    ) async {
      await pumpImages(tester, ':@image(https://example.com/a.png):@');

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

    testWidgets('the size vocabulary reaches the image', (tester) async {
      Image currentImage() {
        final root =
            tester.widget<RichText>(find.byType(RichText).first).text
                as TextSpan;
        final line = root.children!.single as TextSpan;
        return (line.children!.single as WidgetSpan).child as Image;
      }

      await pumpImages(tester, ':@image(https://example.com/a.png):@');
      final plain = currentImage();

      await pumpImages(tester, ':++:@image(https://example.com/a.png):@');
      final bigger = currentImage();

      expect(
        (bigger.image as NetworkImage).scale,
        lessThan((plain.image as NetworkImage).scale),
      );
    });

    testWidgets('the loading placeholder reserves a real height', (
      tester,
    ) async {
      await pumpImages(tester, ':@image(https://example.com/a.png):@');

      final image = tester.widget<Image>(find.byType(Image));
      final placeholder = image.loadingBuilder!(
        tester.element(find.byType(Image)),
        const SizedBox.shrink(),
        const ImageChunkEvent(
          cumulativeBytesLoaded: 1,
          expectedTotalBytes: 100,
        ),
      );

      expect((placeholder as SizedBox).height, isNotNull);
      expect(placeholder.height, greaterThan(0));
    });

    testWidgets('the scale follows the theme, not a hardcoded size', (
      tester,
    ) async {
      await pumpImages(
        tester,
        ':@image(https://example.com/a.png):@',
        theme: const NaturalBlockTheme(baseFontSize: 28),
      );

      final image = tester.widget<Image>(find.byType(Image).first);
      expect((image.image as NetworkImage).scale, 2);
    });

    testWidgets('an image carries a semantic label', (tester) async {
      await pumpImages(tester, ':@image(https://example.com/a.png):@');

      expect(
        tester.widget<Image>(find.byType(Image)).semanticLabel,
        'https://example.com/a.png',
      );
    });

    testWidgets('a local path is declined rather than fetched', (tester) async {
      await pumpImages(tester, r':@image(C:\Users\sugai\a.png):@');

      expect(find.byType(Image), findsNothing);
      expect(renderedSpans(tester).single.text, r'image(C:\Users\sugai\a.png)');
    });

    testWidgets('NaturalBlockImages.local draws a local path from a file', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: r':@image(C:\a.png):@',
            customs: [
              NaturalBlockImages.local,
              NaturalBlockImages.network,
              _links,
            ],
          ),
        ),
      );

      expect(tester.widget<Image>(find.byType(Image)).image, isA<FileImage>());
    });

    testWidgets('NaturalBlockImages.local still draws a network image', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: ':@image(https://example.com/a.png):@',
            customs: [
              NaturalBlockImages.local,
              NaturalBlockImages.network,
              _links,
            ],
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
              customs: [
                NaturalBlockImages.local,
                NaturalBlockImages.network,
                _links,
              ],
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
            customs: [
              NaturalBlockImages.local,
              NaturalBlockImages.network,
              _links,
            ],
          ),
        ),
      );

      expect(find.byType(Image), findsNothing);
      expect(renderedSpans(tester).single.text, 'image(assets/a.png)');
    });

    testWidgets('an app can render local paths by composing', (tester) async {
      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source:
                r':@image(C:\a.png):@ と :@image(https://example.com/b.png):@',
            customs: [_localStandIn, NaturalBlockImages.network],
          ),
        ),
      );

      expect(find.text(r'local:C:\a.png'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });
  });
}
