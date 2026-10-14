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

  testWidgets('only the region inside a sentence is monospaced', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(const NaturalBlockView(source: '比較は`a ^^ b`です')),
    );

    final spans = renderedSpans(tester);
    expect(spans.map((s) => s.text), ['比較は', 'a ^^ b', 'です']);
    expect(spans[1].style!.fontFamily, 'monospace');
    expect(spans[0].style!.fontFamily, isNot('monospace'));
  });

  group('long lines', () {
    testWidgets('scroll sideways when the theme asks', (tester) async {
      await tester.pumpWidget(
        wrap(
          NaturalBlockView(
            source: '`${'word ' * 200}`',
            theme: const NaturalBlockTheme(rawScrollsHorizontally: true),
          ),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(
        tester.widget<RichText>(find.byType(RichText)).softWrap,
        isFalse,
        reason: 'wrapping would leave the scroll view nothing to scroll',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('scrolling still works inside a scrolling parent', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          ListView(
            children: [
              NaturalBlockView(
                source: '`${'word ' * 200}`',
                theme: const NaturalBlockTheme(rawScrollsHorizontally: true),
              ),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('a raw region takes part in selection', (tester) async {
    await tester.pumpWidget(
      wrap(const SelectionArea(child: NaturalBlockView(source: '`copy me`'))),
    );

    expect(
      tester.widget<RichText>(find.byType(RichText)).selectionRegistrar,
      isNotNull,
    );
  });
}
