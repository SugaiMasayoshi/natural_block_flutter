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

  group('the img(...) convention', () {
    test('a payload that names an image yields its URL', () {
      expect(
        NaturalBlockImages.urlOf('img(https://example.com/a.png)'),
        'https://example.com/a.png',
      );
    });

    test('a URL keeps its query string and any parentheses in the path', () {
      // The read-receipt shape is a query string, and it must survive intact
      // -- this package never inspects or rewrites what it carries.
      expect(
        NaturalBlockImages.urlOf('img(https://e.com/x.png?id=you&v=2)'),
        'https://e.com/x.png?id=you&v=2',
      );
      expect(
        NaturalBlockImages.urlOf('img(https://e.com/a_(1).png)'),
        'https://e.com/a_(1).png',
      );
    });

    test('anything else is declined', () {
      for (final text in [
        'https://example.com',
        '#section',
        'img()',
        'image(https://e.com/a.png)',
        'img(https://e.com/a.png) trailing',
        '',
      ]) {
        expect(
          NaturalBlockImages.urlOf(text),
          isNull,
          reason: '"$text" is not the img(...) convention',
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

  group('as an ActionSpanBuilder', () {
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
            onActionBuild: NaturalBlockImages.builder,
            onActionTap: tapped.add,
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
            source: ':@img(https://example.com/a.png):@',
            onActionBuild: NaturalBlockImages.builder,
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
          const NaturalBlockView(source: ':@img(https://example.com/a.png):@'),
        ),
      );

      expect(find.byType(Image), findsNothing);
      expect(renderedSpans(tester).single.text, 'img(https://example.com/a.png)');
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
            source: ':@img(https://example.com/a.png):@',
            onActionBuild: NaturalBlockImages.builder,
          ),
        ),
      );
      final plain = currentImage();

      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: ':++:@img(https://example.com/a.png):@',
            onActionBuild: NaturalBlockImages.builder,
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

    testWidgets('a local path is declined rather than fetched', (
      tester,
    ) async {
      // Drawing one needs `dart:io`, which the web does not have -- taking
      // that on would cost this package its web support. Declining leaves a
      // clean handoff to an app that wants it, and wastes no request in the
      // meantime.
      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: r':@img(C:\Users\sugai\a.png):@',
            onActionBuild: NaturalBlockImages.builder,
          ),
        ),
      );

      expect(find.byType(Image), findsNothing);
      expect(renderedSpans(tester).single.text, r'img(C:\Users\sugai\a.png)');
    });

    testWidgets('an app can render local paths by composing', (tester) async {
      // The pattern the README documents. Note the convention is unchanged
      // -- still `img(...)` -- so supporting local files invents no new
      // spelling and cannot fork the language.
      InlineSpan? withLocalFiles(
        BuildContext context,
        String text,
        TextStyle style,
      ) {
        final source = NaturalBlockImages.urlOf(text);
        if (source != null &&
            NaturalBlockImages.kindOf(source) == ImageSourceKind.file) {
          // Standing in for `Image.file`, which this test cannot use without
          // pulling `dart:io` into a package that deliberately avoids it.
          return WidgetSpan(child: Text('local:$source'));
        }
        return NaturalBlockImages.builder(context, text, style);
      }

      await tester.pumpWidget(
        wrap(
          NaturalBlockView(
            source:
                r':@img(C:\a.png):@ と :@img(https://example.com/b.png):@',
            onActionBuild: withLocalFiles,
          ),
        ),
      );

      expect(find.text(r'local:C:\a.png'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('a builder of your own can fall back to this one', (
      tester,
    ) async {
      InlineSpan? mine(BuildContext context, String text, TextStyle style) {
        if (text.startsWith('user(') && text.endsWith(')')) {
          return TextSpan(
            text: text.substring(5, text.length - 1),
            style: style,
          );
        }
        return NaturalBlockImages.builder(context, text, style);
      }

      await tester.pumpWidget(
        wrap(
          NaturalBlockView(
            source: ':@user(alice):@ and :@img(https://example.com/a.png):@',
            onActionBuild: mine,
          ),
        ),
      );

      expect(renderedSpans(tester).first.text, 'alice');
      expect(find.byType(Image), findsOneWidget);
    });
  });
}
