import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

void main() {
  group('NaturalBlockTheme.styleFor', () {
    const theme = NaturalBlockTheme(fontScaleFor: _doublePerStep);

    TextStyle styleOf(SpanDecoration decoration, {double baseSize = 14}) =>
        theme.styleFor(decoration, baseSize: baseSize);

    test('a size step scales baseSize by fontScaleFor', () {
      expect(styleOf(SpanDecoration(sizeOffset: 2)).fontSize, 14 * 4);
      expect(styleOf(SpanDecoration(sizeOffset: -1)).fontSize, 14 / 2);
      expect(
        styleOf(SpanDecoration(sizeOffset: 1), baseSize: 30).fontSize,
        30 * 2,
      );
    });

    test('no step draws at baseSize', () {
      expect(styleOf(const SpanDecoration()).fontSize, 14);
      expect(styleOf(const SpanDecoration(), baseSize: 30).fontSize, 30);
    });

    test('the space a base height adds stays the same at every size', () {
      const spaced = NaturalBlockTheme(
        base: TextStyle(height: 1.5),
        fontScaleFor: _doublePerStep,
      );
      double spaceAround(int sizeOffset) {
        final style = spaced.styleFor(
          SpanDecoration(sizeOffset: sizeOffset),
          baseSize: 20,
        );
        return style.fontSize! * (style.height! - 1);
      }

      for (final sizeOffset in [-1, 0, 1, 2]) {
        expect(
          spaceAround(sizeOffset),
          closeTo(10, 1e-9),
          reason: '$sizeOffset',
        );
      }
    });

    test('no base height leaves the height to the font', () {
      expect(styleOf(SpanDecoration(sizeOffset: 2)).height, isNull);
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
      'fontScaleFor': base.copyWith(fontScaleFor: _doublePerStep),
      'tableCellPadding': base.copyWith(
        tableCellPadding: const EdgeInsets.all(99),
      ),
      'tableBorder': base.copyWith(tableBorder: const TableBorder()),
      'striped': base.copyWith(striped: true),
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
      final stripe = const NaturalBlockTheme(striped: true)
          .resolve(scheme)
          .tableStripe!;

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

  group('resolve', () {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.deepPurple);

    test('fills the colours a theme leaves open from the scheme', () {
      final theme = const NaturalBlockTheme().resolve(scheme);

      expect(theme.negative.color, scheme.error);
      expect(theme.custom.color, scheme.primary);
      expect(theme.tableBorder?.top.color, scheme.outlineVariant);
      expect(theme.tableStripe, isNull);
      expect(theme.rawDecoration?.color, scheme.surfaceContainerHigh);
    });

    test('keeps what a theme sets, and the rest of its styles', () {
      final theme = const NaturalBlockTheme(
        negative: TextStyle(letterSpacing: 2),
        positive: TextStyle(color: Colors.pink),
        tableBorder: TableBorder(),
        rawDecoration: BoxDecoration(),
      ).resolve(scheme);

      expect(theme.negative.color, scheme.error);
      expect(theme.negative.letterSpacing, 2);
      expect(theme.positive.color, Colors.pink);
      expect(theme.tableBorder, const TableBorder());
      expect(theme.rawDecoration, const BoxDecoration());
    });

    test('stripes when asked', () {
      final striped = const NaturalBlockTheme(striped: true).resolve(scheme);

      expect(striped.tableStripe, scheme.surfaceContainerHigh);
    });

    test('resolving twice changes nothing', () {
      final once = const NaturalBlockTheme().resolve(scheme);

      expect(once.resolve(scheme), once);
    });
  });
}

double _doublePerStep(int sizeOffset) => pow(2, sizeOffset).toDouble();
