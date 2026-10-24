import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

void main() {
  group('NaturalBlockTheme.styleFor', () {
    const theme = NaturalBlockTheme(fontSizeStep: 3);

    TextStyle styleOf(SpanDecoration decoration, {double baseSize = 14}) =>
        theme.styleFor(decoration, baseSize: baseSize);

    test('a size step counts from baseSize', () {
      expect(styleOf(SpanDecoration(sizeOffset: 2)).fontSize, 14 + 2 * 3);
      expect(
        styleOf(SpanDecoration(sizeOffset: 1), baseSize: 30).fontSize,
        30 + 3,
      );
    });

    test('no step draws at baseSize', () {
      expect(styleOf(const SpanDecoration()).fontSize, 14);
      expect(styleOf(const SpanDecoration(), baseSize: 30).fontSize, 30);
    });

    test('base lies under every tone', () {
      const based = NaturalBlockTheme(base: TextStyle(fontFamily: 'Serif'));
      for (final tone in Tone.values) {
        expect(
          based.styleFor(SpanDecoration(tone: tone), baseSize: 14).fontFamily,
          'Serif',
          reason: '$tone',
        );
      }
    });

    test('a step cannot drive the size below minFontSize', () {
      expect(
        styleOf(SpanDecoration(sizeOffset: -99)).fontSize,
        theme.minFontSize,
      );
    });
  });

  group('equality covers every field', () {
    const base = NaturalBlockTheme();

    final differing = <String, NaturalBlockTheme>{
      'base': base.copyWith(base: const TextStyle(letterSpacing: 3)),
      'negative': base.copyWith(negative: const TextStyle(color: Colors.pink)),
      'positive': base.copyWith(positive: const TextStyle(color: Colors.pink)),
      'emphasis': base.copyWith(
        emphasis: const TextStyle(fontStyle: FontStyle.italic),
      ),
      'custom': base.copyWith(custom: const TextStyle(color: Colors.pink)),
      'baseFontSize': base.copyWith(baseFontSize: 99),
      'fontSizeStep': base.copyWith(fontSizeStep: 99),
      'minFontSize': base.copyWith(minFontSize: 99),
      'tableCellPadding': base.copyWith(
        tableCellPadding: const EdgeInsets.all(99),
      ),
      'tableBorder': base.copyWith(tableBorder: const TableBorder()),
      'tableStripe': base.copyWith(tableStripe: const Color(0xFF123456)),
      'raw': base.copyWith(raw: const TextStyle(fontFamily: 'Courier')),
      'rawPadding': base.copyWith(rawPadding: const EdgeInsets.all(99)),
      'rawDecoration': base.copyWith(rawDecoration: const BoxDecoration()),
      'rawScrollsHorizontally': base.copyWith(rawScrollsHorizontally: true),
    };

    for (final entry in differing.entries) {
      test('${entry.key} is part of equality', () {
        expect(
          entry.value,
          isNot(base),
          reason: 'two themes differing only in ${entry.key} are not equal',
        );
        expect(entry.value.hashCode, isNot(base.hashCode));
      });
    }
  });

  test('a stripe darkens a light surface and lightens a dark one', () {
    for (final brightness in Brightness.values) {
      final scheme = ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: brightness,
      );
      final stripe = NaturalBlockTheme.fromColorScheme(
        scheme,
        striped: true,
      ).tableStripe!;

      final surfaceLuminance = scheme.surface.computeLuminance();
      final stripeLuminance = stripe.computeLuminance();

      if (brightness == Brightness.light) {
        expect(
          stripeLuminance,
          lessThan(surfaceLuminance),
          reason: 'a light theme needs a darker band',
        );
      } else {
        expect(
          stripeLuminance,
          greaterThan(surfaceLuminance),
          reason: 'a dark theme needs a lighter band',
        );
      }
      final ratio =
          (max(stripeLuminance, surfaceLuminance) + 0.05) /
          (min(stripeLuminance, surfaceLuminance) + 0.05);
      expect(
        ratio,
        greaterThan(1.1),
        reason: 'the band has to actually be visible in $brightness',
      );
    }
  });

  testWidgets('fromContext counts sizes from the ambient body text, and '
      'stripes when asked', (tester) async {
    late NaturalBlockTheme theme;
    late NaturalBlockTheme striped;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 21)),
        ),
        home: Builder(
          builder: (context) {
            theme = NaturalBlockTheme.fromContext(context);
            striped = NaturalBlockTheme.fromContext(context, striped: true);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(theme.baseFontSize, 21);
    expect(theme.tableStripe, isNull);
    expect(striped.tableStripe, isNotNull);
  });
}
