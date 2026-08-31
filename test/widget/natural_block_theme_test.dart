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
      expect(copy.baseFontSize, theme.baseFontSize);
      expect(copy.minFontSize, theme.minFontSize);
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
  });
}
