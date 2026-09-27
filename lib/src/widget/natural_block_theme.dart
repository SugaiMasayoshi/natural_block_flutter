// 【解説】 読む順番 11/12: 見た目の設定をまとめた値。色合い・強調・操作の書式、
// 【解説】 文字の大きさの段の幅、表の余白・罫線・縞、raw ブロックの書式などを持つ。
// 【解説】 既定値のほか、アプリの ColorScheme(Material の配色)から作る方法もある。
import 'package:flutter/material.dart';
import 'package:natural_block/natural_block.dart';

class NaturalBlockTheme {
  // 【解説】 すべての文字の基準の書式。
  final TextStyle base;

  // 【解説】 :! の run の書式。
  final TextStyle negative;

  // 【解説】 :% の run の書式。
  final TextStyle positive;

  // 【解説】 :* の run の書式。
  final TextStyle emphasis;

  // 【解説】 :@ の run の書式。
  final TextStyle action;

  // 【解説】 祖先から大きさが決まっていないときに使う、基準の文字の大きさ。
  final double baseFontSize;

  // 【解説】 :+ / :- の1段で変わる大きさ。
  final double fontSizeStep;

  // 【解説】 :- を重ねてもこれより小さくはならない。
  final double minFontSize;

  final EdgeInsets tableCellPadding;

  // 【解説】 ? 付きなので null にでき、null なら罫線なし。
  final TableBorder? tableBorder;

  final Color? tableStripe;

  final TextStyle raw;

  final EdgeInsets rawPadding;

  final BoxDecoration? rawDecoration;

  final bool rawScrollsHorizontally;

  // 【解説】 すべての項目に既定値がある const コンストラクタ。NaturalBlockTheme() だけで使える。
  const NaturalBlockTheme({
    this.base = const TextStyle(),
    this.negative = const TextStyle(color: Colors.red),
    this.positive = const TextStyle(color: Colors.green),
    this.emphasis = const TextStyle(fontWeight: FontWeight.bold),
    this.action = const TextStyle(
      color: Colors.blue,
      decoration: TextDecoration.underline,
    ),
    this.baseFontSize = 14,
    this.fontSizeStep = 4,
    this.minFontSize = 1,
    this.tableCellPadding = const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 4,
    ),
    // 【解説】 Color(0x1F000000) は ARGB の16進数。先頭の 1F が不透明度で、薄い黒になる。
    this.tableBorder = const TableBorder.symmetric(
      inside: BorderSide(color: Color(0x1F000000)),
      outside: BorderSide(color: Color(0x1F000000)),
    ),
    this.tableStripe,
    this.raw = const TextStyle(fontFamily: 'monospace'),
    this.rawPadding = const EdgeInsets.all(12),
    this.rawDecoration = const BoxDecoration(
      color: Color(0x0A000000),
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    this.rawScrollsHorizontally = false,
  });

  // 【解説】 factory コンストラクタ: 本体で計算してから、別のコンストラクタで作った値を返せる。
  // 【解説】 Material の配色(ColorScheme)から、色合い・操作・罫線の色を決める。
  factory NaturalBlockTheme.fromColorScheme(
    ColorScheme scheme, {
    TextStyle base = const TextStyle(),
    TextStyle emphasis = const TextStyle(fontWeight: FontWeight.bold),
    double baseFontSize = 14,
    double fontSizeStep = 4,
    double minFontSize = 1,
    EdgeInsets tableCellPadding = const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 4,
    ),
    bool striped = false,
  }) {
    // 【解説】 罫線1本の設定。配色の「控えめな輪郭の色」を使う。
    final rule = BorderSide(color: scheme.outlineVariant);
    return NaturalBlockTheme(
      base: base,
      negative: TextStyle(color: scheme.error),
      positive: TextStyle(color: scheme.tertiary),
      emphasis: emphasis,
      action: TextStyle(
        color: scheme.primary,
        decoration: TextDecoration.underline,
      ),
      baseFontSize: baseFontSize,
      fontSizeStep: fontSizeStep,
      minFontSize: minFontSize,
      tableCellPadding: tableCellPadding,
      // 【解説】 縞ありなら行の間の横線を引かない(縞が行を分ける)。縞なしなら内側も外側も線を引く。
      tableBorder: striped
          ? TableBorder(
              top: rule,
              right: rule,
              bottom: rule,
              left: rule,
              verticalInside: rule,
            )
          : TableBorder.symmetric(inside: rule, outside: rule),
      tableStripe: striped ? scheme.surfaceContainerHigh : null,
    );
  }

  // 【解説】 アプリのテーマ(Theme.of(context))の配色から作る近道。
  factory NaturalBlockTheme.fromContext(
    BuildContext context, {
    bool striped = false,
  }) => NaturalBlockTheme.fromColorScheme(
    Theme.of(context).colorScheme,
    striped: striped,
  );

  // 【解説】 色合いの値から、その書式を選ぶ。switch 式なので Tone を増やすと、ここがコンパイルエラーで知らせる。
  TextStyle styleFor(Tone tone) => switch (tone) {
    Tone.negative => negative,
    Tone.positive => positive,
    Tone.none => base,
  };

  // 【解説】 「引数が渡されなかった」ことを表す番兵(目印)の値。
  // 【解説】 null は「罫線を消す」という意味で使いたいので、「変えない」を null とは別に表す必要がある。
  static const Object _unchanged = Object();

  NaturalBlockTheme copyWith({
    TextStyle? base,
    TextStyle? negative,
    TextStyle? positive,
    TextStyle? emphasis,
    TextStyle? action,
    double? baseFontSize,
    double? fontSizeStep,
    double? minFontSize,
    EdgeInsets? tableCellPadding,
    // 【解説】 型を Object? にして既定値を番兵にしている。渡さなければ _unchanged、null を渡せば null。
    Object? tableBorder = _unchanged,
    Object? tableStripe = _unchanged,
    TextStyle? raw,
    EdgeInsets? rawPadding,
    Object? rawDecoration = _unchanged,
    bool? rawScrollsHorizontally,
  }) {
    // 【解説】 型が Object? なので、間違った型を渡してもコンパイルは通る。デバッグ時にここで捕まえる。
    // 【解説】 is TableBorder? は「TableBorder か null か」の判定。
    assert(
      tableBorder == _unchanged || tableBorder is TableBorder?,
      'tableBorder must be a TableBorder or null',
    );
    assert(
      tableStripe == _unchanged || tableStripe is Color?,
      'tableStripe must be a Color or null',
    );
    assert(
      rawDecoration == _unchanged || rawDecoration is BoxDecoration?,
      'rawDecoration must be a BoxDecoration or null',
    );
    return NaturalBlockTheme(
      // 【解説】 base ?? this.base: 引数が渡されていれば(null でなければ)それ、無ければ今の値。
      base: base ?? this.base,
      negative: negative ?? this.negative,
      positive: positive ?? this.positive,
      emphasis: emphasis ?? this.emphasis,
      action: action ?? this.action,
      baseFontSize: baseFontSize ?? this.baseFontSize,
      fontSizeStep: fontSizeStep ?? this.fontSizeStep,
      minFontSize: minFontSize ?? this.minFontSize,
      tableCellPadding: tableCellPadding ?? this.tableCellPadding,
      // 【解説】 identical: 同じオブジェクトかどうか。番兵のままなら今の値、そうでなければ渡された値。
      // 【解説】 as TableBorder? で、Object? から本来の型に戻している。
      tableBorder: identical(tableBorder, _unchanged)
          ? this.tableBorder
          : tableBorder as TableBorder?,
      tableStripe: identical(tableStripe, _unchanged)
          ? this.tableStripe
          : tableStripe as Color?,
      raw: raw ?? this.raw,
      rawPadding: rawPadding ?? this.rawPadding,
      rawDecoration: identical(rawDecoration, _unchanged)
          ? this.rawDecoration
          : rawDecoration as BoxDecoration?,
      rawScrollsHorizontally:
          rawScrollsHorizontally ?? this.rawScrollsHorizontally,
    );
  }

  // 【解説】 全項目が同じなら等しい。テーマの変更を見分けるために使う。
  @override
  bool operator ==(Object other) {
    // 【解説】 同じオブジェクトなら、項目を比べるまでもなく等しい(速くするための近道)。
    if (identical(this, other)) return true;
    return other is NaturalBlockTheme &&
        base == other.base &&
        negative == other.negative &&
        positive == other.positive &&
        emphasis == other.emphasis &&
        action == other.action &&
        baseFontSize == other.baseFontSize &&
        fontSizeStep == other.fontSizeStep &&
        minFontSize == other.minFontSize &&
        tableCellPadding == other.tableCellPadding &&
        tableBorder == other.tableBorder &&
        tableStripe == other.tableStripe &&
        raw == other.raw &&
        rawPadding == other.rawPadding &&
        rawDecoration == other.rawDecoration &&
        rawScrollsHorizontally == other.rawScrollsHorizontally;
  }

  // 【解説】 == を上書きしたら hashCode も揃える決まり。等しい値は同じハッシュになる必要がある。
  @override
  int get hashCode => Object.hash(
    base,
    negative,
    positive,
    emphasis,
    action,
    baseFontSize,
    fontSizeStep,
    minFontSize,
    tableCellPadding,
    tableBorder,
    tableStripe,
    raw,
    rawPadding,
    rawDecoration,
    rawScrollsHorizontally,
  );
}
