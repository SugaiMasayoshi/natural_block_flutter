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
