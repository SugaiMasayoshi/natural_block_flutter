// 【解説】[テスト17/21] テーマ。「意味」から「見た目」への対応表の検算。
// 【解説】
// 【解説】 copyWith の group が長いのには理由がある。tableBorder と
// 【解説】 tableStripe は null 可能なので、「null を渡して消す」と
// 【解説】 「省略して保つ」を区別しなければならない。普通の copyWith では
// 【解説】 書けないので番兵を置いていて、その番兵が効いていることの確認。
// 【解説】
// 【解説】 "equality covers every field" は、フィールドを増やしたときに
// 【解説】 == への追加を忘れないための網。忘れると差し替えても再描画されない。
// 【解説】
// 【解説】 縞が fromColorScheme にしか無いのも見ている。帯は明るい配色では
// 【解説】 地より暗く、暗い配色では明るくなければならず、固定値では両立しない。
// 【解説】 次: test/registry/natural_block_registry_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

void main() {
  group('NaturalBlockTheme.styleFor', () {
    const theme = NaturalBlockTheme();

    test('SemanticColor.danger returns danger', () {
      expect(theme.styleFor(SemanticColor.danger), theme.danger);
    });

    test('SemanticColor.success returns success', () {
      expect(theme.styleFor(SemanticColor.success), theme.success);
    });

    test('SemanticColor.info returns info', () {
      expect(theme.styleFor(SemanticColor.info), theme.info);
    });

    test('SemanticColor.none returns base', () {
      expect(theme.styleFor(SemanticColor.none), theme.base);
    });
  });

  group('NaturalBlockTheme.copyWith', () {
    test('replaces only the given fields, keeping the rest', () {
      const theme = NaturalBlockTheme();
      final copy = theme.copyWith(
        danger: const TextStyle(color: Colors.purple),
        fontSizeStep: 10,
      );

      expect(copy.danger, const TextStyle(color: Colors.purple));
      expect(copy.fontSizeStep, 10);
      expect(copy.base, theme.base);
      expect(copy.success, theme.success);
      expect(copy.info, theme.info);
      expect(copy.emphasis, theme.emphasis);
      expect(copy.action, theme.action);
      expect(copy.baseFontSize, theme.baseFontSize);
      expect(copy.minFontSize, theme.minFontSize);
    });

    test('replaces action when given', () {
      const theme = NaturalBlockTheme();
      final copy = theme.copyWith(action: const TextStyle(color: Colors.pink));

      expect(copy.action, const TextStyle(color: Colors.pink));
      expect(copy.danger, theme.danger);
    });

    test('called with no arguments returns an equal copy', () {
      const theme = NaturalBlockTheme();
      expect(theme.copyWith(), theme);
    });
  });

  group('NaturalBlockTheme equality', () {
    test('two themes with the same field values are equal and hash equal', () {
      const a = NaturalBlockTheme();
      const b = NaturalBlockTheme();

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('themes differing in one field are not equal', () {
      const a = NaturalBlockTheme();
      const b = NaturalBlockTheme(danger: TextStyle(color: Colors.purple));

      expect(a, isNot(b));
    });

    test('themes differing only in action are not equal', () {
      const a = NaturalBlockTheme();
      const b = NaturalBlockTheme(action: TextStyle(color: Colors.pink));

      expect(a, isNot(b));
      expect(a.hashCode, isNot(b.hashCode));
    });
  });

  group('NaturalBlockTheme.fromColorScheme', () {
    test('danger picks up the scheme\'s error color', () {
      const scheme = ColorScheme.light(error: Colors.orange);
      final theme = NaturalBlockTheme.fromColorScheme(scheme);

      expect(theme.danger.color, Colors.orange);
    });

    test('success and info pick up tertiary and primary respectively', () {
      const scheme = ColorScheme.light(
        tertiary: Colors.teal,
        primary: Colors.indigo,
      );
      final theme = NaturalBlockTheme.fromColorScheme(scheme);

      expect(theme.success.color, Colors.teal);
      expect(theme.info.color, Colors.indigo);
    });

    test('action picks up primary and is underlined', () {
      const scheme = ColorScheme.light(primary: Colors.indigo);
      final theme = NaturalBlockTheme.fromColorScheme(scheme);

      expect(theme.action.color, Colors.indigo);
      expect(theme.action.decoration, TextDecoration.underline);
    });

    group('copyWith', () {
      test('an omitted argument leaves the value alone', () {
        const base = NaturalBlockTheme();
        final copy = base.copyWith(baseFontSize: 20);

        expect(copy.baseFontSize, 20);
        expect(copy.tableBorder, base.tableBorder);
        expect(copy.danger, base.danger);
      });

      test('passing null clears a nullable field', () {
        // The two nullable fields need `null` to mean *clear*, or a themed
        // table can never lose its rules: with the usual `?? this.x` form,
        // an explicit null is indistinguishable from omitting the argument.
        const base = NaturalBlockTheme(tableStripe: Color(0xFFEEEEEE));

        expect(base.tableBorder, isNotNull);
        expect(base.copyWith(tableBorder: null).tableBorder, isNull);
        expect(base.copyWith(tableStripe: null).tableStripe, isNull);
      });

      test('clearing one nullable field leaves the other', () {
        const base = NaturalBlockTheme(tableStripe: Color(0xFFEEEEEE));
        final copy = base.copyWith(tableBorder: null);

        expect(copy.tableBorder, isNull);
        expect(copy.tableStripe, base.tableStripe);
      });
    });

    group('equality covers every field', () {
      // Checked field by field rather than with one differing value: with a
      // hand-written `==`, a field added to the class but forgotten in the
      // comparison ships green, and a single-field test would never see it.
      const base = NaturalBlockTheme();

      final differing = <String, NaturalBlockTheme>{
        'base': base.copyWith(base: const TextStyle(letterSpacing: 3)),
        'danger': base.copyWith(danger: const TextStyle(color: Colors.pink)),
        'success': base.copyWith(success: const TextStyle(color: Colors.pink)),
        'info': base.copyWith(info: const TextStyle(color: Colors.pink)),
        'emphasis': base.copyWith(
          emphasis: const TextStyle(fontStyle: FontStyle.italic),
        ),
        'action': base.copyWith(action: const TextStyle(color: Colors.pink)),
        'baseFontSize': base.copyWith(baseFontSize: 99),
        'fontSizeStep': base.copyWith(fontSizeStep: 99),
        'minFontSize': base.copyWith(minFontSize: 99),
        'tableCellPadding': base.copyWith(
          tableCellPadding: const EdgeInsets.all(99),
        ),
        'tableBorder': base.copyWith(tableBorder: null),
        'tableStripe': base.copyWith(tableStripe: const Color(0xFF123456)),
        'verbatim': base.copyWith(
          verbatim: const TextStyle(fontFamily: 'Courier'),
        ),
        'verbatimPadding': base.copyWith(
          verbatimPadding: const EdgeInsets.all(99),
        ),
        'verbatimDecoration': base.copyWith(verbatimDecoration: null),
        'verbatimScrollsHorizontally': base.copyWith(
          verbatimScrollsHorizontally: true,
        ),
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

      /// Perceived lightness, enough to tell "darker than" from "lighter
      /// than" without pulling in a color-science dependency.
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
        // The entire reason this lives on `fromColorScheme` and not on the
        // default constructor: the band has to move in opposite directions
        // depending on the theme, so no single constant could serve both.
        // A fixed translucent black shifts a light surface visibly and a
        // dark one by about one step per channel -- invisible.
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
        // Both answer "which cells belong to one row", so drawing both is
        // noise; the vertical rules and the frame are doing another job.
        final theme = NaturalBlockTheme.fromColorScheme(
          schemeFor(Brightness.light),
          striped: true,
        );
        final border = theme.tableBorder!;

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
        ).tableBorder!;

        expect(border.horizontalInside.style, BorderStyle.solid);
      });
    });
  });
}
