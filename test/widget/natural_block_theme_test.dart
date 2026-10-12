import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

void main() {
  group('NaturalBlockTheme.styleFor', () {
    const theme = NaturalBlockTheme();

    TextStyle styleOf(SpanDecoration decoration, {double baseSize = 14}) =>
        theme.styleFor(decoration, baseSize: baseSize);

    test('a tone picks that tone\'s style', () {
      expect(
        styleOf(SpanDecoration(tone: Tone.negative)).color,
        theme.negative.color,
      );
      expect(
        styleOf(SpanDecoration(tone: Tone.positive)).color,
        theme.positive.color,
      );
      expect(styleOf(const SpanDecoration()).color, theme.base.color);
    });

    test('emphasis and custom marking lay over the tone', () {
      final both = styleOf(
        SpanDecoration(tone: Tone.negative, emphasis: true, isCustom: true),
      );

      expect(both.color, theme.custom.color, reason: 'custom is laid last');
      expect(both.fontWeight, theme.emphasis.fontWeight);
      expect(both.decoration, theme.custom.decoration);
    });

    test('a size step counts from baseSize', () {
      expect(
        styleOf(SpanDecoration(sizeOffset: 2)).fontSize,
        14 + 2 * theme.fontSizeStep,
      );
      expect(
        styleOf(SpanDecoration(sizeOffset: 1), baseSize: 30).fontSize,
        30 + theme.fontSizeStep,
      );
    });

    test('no step leaves the size unstated', () {
      expect(styleOf(const SpanDecoration()).fontSize, isNull);
    });

    test('a step cannot drive the size below minFontSize', () {
      expect(
        styleOf(SpanDecoration(sizeOffset: -99)).fontSize,
        theme.minFontSize,
      );
    });
  });

  group('NaturalBlockTheme.copyWith', () {
    test('replaces only the given fields, keeping the rest', () {
      const theme = NaturalBlockTheme();
      final copy = theme.copyWith(
        negative: const TextStyle(color: Colors.purple),
        fontSizeStep: 10,
      );

      expect(copy.negative, const TextStyle(color: Colors.purple));
      expect(copy.fontSizeStep, 10);
      expect(copy.base, theme.base);
      expect(copy.positive, theme.positive);
      expect(copy.emphasis, theme.emphasis);
      expect(copy.custom, theme.custom);
      expect(copy.baseFontSize, theme.baseFontSize);
      expect(copy.minFontSize, theme.minFontSize);
    });

    test('called with no arguments returns an equal copy', () {
      const theme = NaturalBlockTheme();
      expect(theme.copyWith(), theme);
    });
  });

  group('NaturalBlockTheme.fromColorScheme', () {
    test('negative picks up the scheme\'s error color', () {
      const scheme = ColorScheme.light(error: Colors.orange);
      final theme = NaturalBlockTheme.fromColorScheme(scheme);

      expect(theme.negative.color, Colors.orange);
    });

    test('positive picks up tertiary', () {
      const scheme = ColorScheme.light(
        tertiary: Colors.teal,
        primary: Colors.indigo,
      );
      final theme = NaturalBlockTheme.fromColorScheme(scheme);

      expect(theme.positive.color, Colors.teal);
    });

    test('custom picks up primary and is underlined', () {
      const scheme = ColorScheme.light(primary: Colors.indigo);
      final theme = NaturalBlockTheme.fromColorScheme(scheme);

      expect(theme.custom.color, Colors.indigo);
      expect(theme.custom.decoration, TextDecoration.underline);
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

    test('an identical theme is equal', () {
      expect(const NaturalBlockTheme(), base);
      expect(const NaturalBlockTheme().hashCode, base.hashCode);
    });
  });

  group('striped tables', () {
    ColorScheme schemeFor(Brightness brightness) => ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: brightness,
    );

    double luminance(Color color) => color.computeLuminance();

    test('striping is off unless asked for', () {
      expect(
        NaturalBlockTheme.fromColorScheme(schemeFor(Brightness.light))
            .tableStripe,
        isNull,
      );
      expect(const NaturalBlockTheme().tableStripe, isNull);
    });

    test('the band darkens a light surface and lightens a dark one', () {
      for (final brightness in Brightness.values) {
        final scheme = schemeFor(brightness);
        final stripe = NaturalBlockTheme.fromColorScheme(
          scheme,
          striped: true,
        ).tableStripe!;

        final surfaceLuminance = luminance(scheme.surface);
        final stripeLuminance = luminance(stripe);

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
        expect(
          (stripeLuminance - surfaceLuminance).abs(),
          greaterThan(0.005),
          reason: 'the band has to actually be visible in $brightness',
        );
      }
    });

    test('striping replaces the horizontal rules but keeps the rest', () {
      final theme = NaturalBlockTheme.fromColorScheme(
        schemeFor(Brightness.light),
        striped: true,
      );
      final border = theme.tableBorder;

      expect(border.horizontalInside.style, BorderStyle.none);
      expect(border.verticalInside.style, BorderStyle.solid);
      for (final side in [
        border.top,
        border.bottom,
        border.left,
        border.right,
      ]) {
        expect(side.style, BorderStyle.solid);
      }
    });

    test('unstriped keeps the horizontal rules', () {
      final border = NaturalBlockTheme.fromColorScheme(
        schemeFor(Brightness.light),
      ).tableBorder;

      expect(border.horizontalInside.style, BorderStyle.solid);
    });
  });

  testWidgets('fromContext counts sizes from the ambient body text', (
    tester,
  ) async {
    late NaturalBlockTheme theme;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 21)),
        ),
        home: Builder(
          builder: (context) {
            theme = NaturalBlockTheme.fromContext(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(theme.baseFontSize, 21);
  });
}
