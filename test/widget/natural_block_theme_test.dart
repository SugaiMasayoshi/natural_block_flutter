// 【解説】読む順番 4/9：テーマ。装飾がどの書式になるか（styleFor）。次の行のテストの前提。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

void main() {
  // 【解説】styleFor の大きさの段の計算を直接確かめる（色や強調はゴールデンの decorations で見ている）。段の幅を既定の4ではなく3にして、既定値に頼った計算の誤りも見つかるようにしている。
  // 【解説】画面には何も出さない純粋な計算のテスト。
  group('NaturalBlockTheme.styleFor', () {
    const theme = NaturalBlockTheme(fontSizeStep: 3);

    // 【解説】基準の大きさを省略すると14で計算する補助。
    TextStyle styleOf(SpanDecoration decoration, {double baseSize = 14}) =>
        theme.styleFor(decoration, baseSize: baseSize);

    // 【解説】`:+` 1段ごとに fontSizeStep ずつ大きくなり、基準は baseSize であること。
    // 【解説】14 から2段なら 14 + 2×段の幅、30 から1段なら 30 + 段の幅。
    test('a size step counts from baseSize', () {
      expect(styleOf(SpanDecoration(sizeOffset: 2)).fontSize, 14 + 2 * 3);
      expect(
        styleOf(SpanDecoration(sizeOffset: 1), baseSize: 30).fontSize,
        30 + 3,
      );
    });

    // 【解説】段が0なら baseSize そのままの大きさで描くこと（null にして周りに任せない）。
    test('no step draws at baseSize', () {
      expect(styleOf(const SpanDecoration()).fontSize, 14);
      expect(styleOf(const SpanDecoration(), baseSize: 30).fontSize, 30);
    });

    // 【解説】`:-` を何段重ねても minFontSize より小さくならないこと（0やマイナスにならない）。
    test('a step cannot drive the size below minFontSize', () {
      expect(
        styleOf(SpanDecoration(sizeOffset: -99)).fontSize,
        theme.minFontSize,
      );
    });
  });

  // 【解説】テーマの == と hashCode が15項目すべてを見ていること。1つでも漏れると、その項目だけを
  // 【解説】変えたテーマを渡しても文書が描き直されない。
  group('equality covers every field', () {
    const base = NaturalBlockTheme();

    // 【解説】項目ごとに「その1つだけ既定と違う」テーマを copyWith で作る。
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

    // 【解説】項目ごとに test を1つずつ作り、既定と等しくないこと、hashCode も違うことを確かめる。
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

  // 【解説】縞の色が、明るいテーマでは背景より暗く、暗いテーマでは背景より明るいこと。差が小さすぎて
  // 【解説】見えない、ということもないこと。ゴールデンは明るいテーマしか描かないので、ここで両方を見る。
  // 【解説】`computeLuminance` は色の明るさを 0（黒）〜1（白）で返す。
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
      expect(
        (stripeLuminance - surfaceLuminance).abs(),
        greaterThan(0.005),
        reason: 'the band has to actually be visible in $brightness',
      );
    }
  });

  // 【解説】アプリのテーマ（本文の大きさ21）から作ると、基準の大きさが21になること。
  // 【解説】`striped: true` を渡したときだけ縞の色が入ること。
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
