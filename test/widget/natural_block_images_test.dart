import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

import '../rendered_spans.dart';

/// A local-file handler standing in for `NaturalBlockImages.local`, which
/// this test cannot exercise without a file on disk.
RunRendering? _localStandIn(
  BuildContext context,
  String text,
  TextStyle style,
  NaturalBlockTheme theme,
  VoidCallback? onTap,
) {
  final source = NaturalBlockImages.urlOf(text);
  if (source == null ||
      NaturalBlockImages.kindOf(source) != ImageSourceKind.file) {
    return null;
  }
  return WidgetRun(Text('local:$source'));
}

/// A handler of the app's own, which claims `user(...)` and declines the rest.
RunRendering? _mentions(
  BuildContext context,
  String text,
  TextStyle style,
  NaturalBlockTheme theme,
  VoidCallback? onTap,
) => text.startsWith('user(') && text.endsWith(')')
    ? TextRun(text: text.substring(5, text.length - 1))
    : null;

/// Draws any actionable run as a box that answers the tap itself, through a
/// widget rather than a recognizer this package would have to release.
RunRendering? _tappableBox(
  BuildContext context,
  String text,
  TextStyle style,
  NaturalBlockTheme theme,
  VoidCallback? onTap,
) => WidgetRun(
  GestureDetector(
    // An empty box defers its hit testing to a child it does not have.
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: const SizedBox(width: 20, height: 20),
  ),
);

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: DefaultTextStyle(
      style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
      child: child,
    ),
  );

  group('the image(...) convention', () {
    test('a payload that names an image yields its URL', () {
      expect(
        NaturalBlockImages.urlOf('image(https://example.com/a.png)'),
        'https://example.com/a.png',
      );
    });

    test('a URL keeps its query string and any parentheses in the path', () {
      // The read-receipt shape is a query string, and it must survive intact
      // -- this package never inspects or rewrites what it carries.
      expect(
        NaturalBlockImages.urlOf('image(https://e.com/x.png?id=you&v=2)'),
        'https://e.com/x.png?id=you&v=2',
      );
      expect(
        NaturalBlockImages.urlOf('image(https://e.com/a_(1).png)'),
        'https://e.com/a_(1).png',
      );
    });

    test('anything else is declined, `img` included', () {
      for (final text in [
        'https://example.com',
        '#section',
        'image()',
        // The abbreviation is not an alias: one convention, one spelling,
        // or the thing meant to prevent dialects becomes one.
        'img(https://e.com/a.png)',
        'IMAGE(https://e.com/a.png)',
        'image(https://e.com/a.png) trailing',
        '',
      ]) {
        expect(
          NaturalBlockImages.urlOf(text),
          isNull,
          reason: '"$text" is not the image(...) convention',
        );
      }
    });
  });

  group('classifying where a payload points', () {
    const bs = r'\';

    test('a URL is a network source', () {
      for (final source in [
        'https://example.com/a.png',
        'http://example.com/a.png',
        'https://e.com/x.png?id=you',
      ]) {
        expect(NaturalBlockImages.kindOf(source), ImageSourceKind.network);
      }
    });

    test('a Windows path is a file, not a URL with scheme "c"', () {
      // The trap this helper exists for. `Uri.parse` reads `C:\Users\a.png`
      // as a URI whose scheme is `c`, so any "has a scheme, therefore a URL"
      // test mistakes every Windows path for one.
      expect(Uri.parse('C:${bs}Users${bs}a.png').scheme, 'c');

      for (final source in [
        'C:${bs}Users${bs}sugai${bs}a.png',
        'C:/Users/sugai/a.png',
        'D:${bs}photos${bs}My Pictures${bs}a.png',
        'c:${bs}lower${bs}a.png',
      ]) {
        expect(
          NaturalBlockImages.kindOf(source),
          ImageSourceKind.file,
          reason: '"$source" is a path',
        );
      }
    });

    test('UNC and POSIX absolute paths are files', () {
      expect(
        NaturalBlockImages.kindOf('$bs${bs}server${bs}share${bs}a.png'),
        ImageSourceKind.file,
      );
      expect(
        NaturalBlockImages.kindOf('/home/sugai/a.png'),
        ImageSourceKind.file,
      );
    });

    test('a file: URI is a file', () {
      expect(
        NaturalBlockImages.kindOf('file:///C:/Users/a.png'),
        ImageSourceKind.file,
      );
    });

    test('anything with no scheme and no root is left to the app', () {
      for (final source in ['./assets/a.png', 'assets/a.png', 'a.png', '']) {
        expect(
          NaturalBlockImages.kindOf(source),
          ImageSourceKind.relative,
          reason: '"$source" is only resolvable by the app',
        );
      }
    });
  });

  group('as a run handler', () {
    testWidgets('declining leaves the run as ordinary actionable text', (
      tester,
    ) async {
      // The property that makes the extension point safe: a builder never
      // has to understand every payload it meets, and one it does not
      // understand still reads as text rather than disappearing.
      final tapped = <String>[];
      await tester.pumpWidget(
        wrap(
          NaturalBlockView(
            source: ':@#section:@',
            customs: [NaturalBlockImages.network, tappableText],
            onTap: tapped.add,
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

    testWidgets('an image payload becomes a WidgetSpan, not text', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: ':@image(https://example.com/a.png):@',
            customs: [NaturalBlockImages.network, tappableText],
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final child = (richText.text as TextSpan).children!.single as TextSpan;

      expect(
        child.children!.single,
        isA<WidgetSpan>(),
        reason: 'the run renders as a widget rather than as its text',
      );
    });

    testWidgets('nothing is fetched unless a builder is supplied', (
      tester,
    ) async {
      // The default: displaying a document must not reach out to a third
      // party on its own, because that request is indistinguishable from a
      // tracking pixel and the reader was never asked.
      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: ':@image(https://example.com/a.png):@',
          ),
        ),
      );

      expect(find.byType(Image), findsNothing);
      expect(
        renderedSpans(tester).single.text,
        'image(https://example.com/a.png)',
      );
    });

    testWidgets('the size vocabulary reaches the image', (tester) async {
      // Block alignment reaches an image for free, since it moves the whole
      // block; size only arrives because the builder reads the style it was
      // handed. Shipping the builder is what makes that a guarantee.
      // `.first`, not `.single`: with no network in a test the image fails
      // and its errorBuilder renders the payload as text, which is itself a
      // RichText nested inside the WidgetSpan. That fallback working is the
      // point -- it just means the outer paragraph is no longer the only one.
      Image currentImage() {
        final root =
            tester.widget<RichText>(find.byType(RichText).first).text
                as TextSpan;
        final line = root.children!.single as TextSpan;
        return (line.children!.single as WidgetSpan).child as Image;
      }

      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: ':@image(https://example.com/a.png):@',
            customs: [NaturalBlockImages.network, tappableText],
          ),
        ),
      );
      final plain = currentImage();

      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: ':++:@image(https://example.com/a.png):@',
            customs: [NaturalBlockImages.network, tappableText],
          ),
        ),
      );
      final bigger = currentImage();

      // `scale` divides, so asking for bigger text has to lower it.
      expect(
        (bigger.image as NetworkImage).scale,
        lessThan((plain.image as NetworkImage).scale),
      );
    });

    testWidgets('the loading placeholder reserves a real height', (
      tester,
    ) async {
      // `style.fontSize` is null for every run without size markup, so
      // reading it directly gave `SizedBox(height: null)` -- a zero-sized
      // box that reserved nothing in the ordinary case, which is exactly
      // the case the placeholder exists for. The theme's base size is what
      // an unmarked run actually renders at.
      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: ':@image(https://example.com/a.png):@',
            customs: [NaturalBlockImages.network, tappableText],
          ),
        ),
      );

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
      // The builder used to compare against a literal 14.0, duplicating the
      // theme's default and drifting the moment anyone changed it.
      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: ':@image(https://example.com/a.png):@',
            customs: [NaturalBlockImages.network, tappableText],
            theme: NaturalBlockTheme(baseFontSize: 28),
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image).first);
      // The ambient size is 14 and the theme's base is 28, so an unmarked
      // run is half the base and the image is drawn at half size -- which
      // `scale`, dividing, expresses as 2.
      expect((image.image as NetworkImage).scale, 2);
    });

    testWidgets('an image carries a semantic label', (tester) async {
      // Without one a screen reader announces nothing at all where a
      // sighted reader sees a picture.
      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: ':@image(https://example.com/a.png):@',
            customs: [NaturalBlockImages.network, tappableText],
          ),
        ),
      );

      expect(
        tester.widget<Image>(find.byType(Image)).semanticLabel,
        'https://example.com/a.png',
      );
    });

    testWidgets('a local path is declined rather than fetched', (tester) async {
      // Drawing one needs `dart:io`, which the web does not have -- taking
      // that on would cost this package its web support. Declining leaves a
      // clean handoff to an app that wants it, and wastes no request in the
      // meantime.
      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: r':@image(C:\Users\sugai\a.png):@',
            customs: [NaturalBlockImages.network, tappableText],
          ),
        ),
      );

      expect(find.byType(Image), findsNothing);
      expect(renderedSpans(tester).single.text, r'image(C:\Users\sugai\a.png)');
    });

    testWidgets('withLocalFiles draws a local path from a file', (
      tester,
    ) async {
      // The second entry point, for an app that knows its documents name
      // files the reader is meant to see -- a note shared between the
      // reader's own machines, say.
      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: r':@image(C:\a.png):@',
            customs: [
              NaturalBlockImages.local,
              NaturalBlockImages.network,
              tappableText,
            ],
          ),
        ),
      );

      expect(tester.widget<Image>(find.byType(Image)).image, isA<FileImage>());
    });

    testWidgets('withLocalFiles still draws a network image', (tester) async {
      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: ':@image(https://example.com/a.png):@',
            customs: [
              NaturalBlockImages.local,
              NaturalBlockImages.network,
              tappableText,
            ],
          ),
        ),
      );

      expect(
        tester.widget<Image>(find.byType(Image)).image,
        isA<NetworkImage>(),
      );
    });

    testWidgets('withLocalFiles declines a file URI it cannot turn into a '
        'path, rather than throwing', (tester) async {
      // `Uri.toFilePath` throws for a query, a fragment, or an authority off
      // Windows. A document is outside input, so one of those has to read as
      // text like any other payload the builder does not handle -- throwing
      // would break the line it sits on.
      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: ':@image(file:///a.png?v=1):@',
            customs: [
              NaturalBlockImages.local,
              NaturalBlockImages.network,
              tappableText,
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(Image), findsNothing);
      expect(renderedSpans(tester).single.text, 'image(file:///a.png?v=1)');
    });

    testWidgets('withLocalFiles leaves a relative path to the app', (
      tester,
    ) async {
      // Resolving `assets/a.png` needs something only the app has: an asset
      // bundle, or a base to join it to.
      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: ':@image(assets/a.png):@',
            customs: [
              NaturalBlockImages.local,
              NaturalBlockImages.network,
              tappableText,
            ],
          ),
        ),
      );

      expect(find.byType(Image), findsNothing);
      expect(renderedSpans(tester).single.text, 'image(assets/a.png)');
    });

    testWidgets('an app can render local paths by composing', (tester) async {
      // Standing in for the real `NaturalBlockImages.local`, which this test
      // cannot exercise without a file on disk.
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

    testWidgets('handlers are tried in order, and the first one wins', (
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
  });

  group('customs as a chain', () {
    testWidgets('leaving tappableText out keeps the style and drops the tap', (
      tester,
    ) async {
      // The default is a handler like any other, so an app can take it away.
      final tapped = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: NaturalBlockView(
            source: ':@リンク:@',
            customs: const [],
            onTap: tapped.add,
          ),
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
      expect(tapped, isEmpty);
    });

    testWidgets(
      'a widget run answers a tap through Flutter, not a recognizer',
      (tester) async {
        // What makes replacement and tappability independent: anything inside a
        // WidgetRun is Flutter's to manage, so nothing here owns a recognizer.
        final tapped = <String>[];
        await tester.pumpWidget(
          MaterialApp(
            home: Align(
              alignment: Alignment.topLeft,
              child: NaturalBlockView(
                source: ':@box:@',
                customs: const [_tappableBox],
                onTap: tapped.add,
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

    testWidgets('a widget run brings no recognizer for this package to hold', (
      tester,
    ) async {
      // What a handler returns can only be a span this package made, so every
      // recognizer in one is its own to release. A widget run carries none:
      // whatever answers a tap there is a widget, and Flutter owns it.
      await tester.pumpWidget(
        MaterialApp(
          home: Align(
            alignment: Alignment.topLeft,
            child: NaturalBlockView(
              source: ':@box:@',
              customs: const [_tappableBox],
              onTap: (_) {},
            ),
          ),
        ),
      );

      final recognizers = <Object>[];
      void walk(InlineSpan span) {
        if (span is TextSpan && span.recognizer != null) {
          recognizers.add(span.recognizer!);
        }
        span.visitChildren((child) {
          if (!identical(child, span)) walk(child);
          return true;
        });
      }

      walk(tester.widget<RichText>(find.byType(RichText)).text);
      expect(recognizers, isEmpty);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });
  });
}
