// 【解説】[11/16] 「意味」から「見た目」への対応表。パーサ側が SemanticColor.danger
// 【解説】 としか言わないのに対し、それを実際に何色で描くかを決めるのがここ。
// 【解説】 この一枚があるおかげで、配色の都合がパーサに一切漏れない。
// 【解説】
// 【解説】 読みどころ:
// 【解説】  ・const で作れることを維持している(NaturalBlockView の既定値がconst)
// 【解説】  ・fromContext という名前。.of() にしなかったのは、Flutterの慣習で
// 【解説】    .of() は InheritedWidget の探索を意味し、ここはただの変換だから
// 【解説】  ・baseFontSize / fontSizeStep / minFontSize が外出しされている。
// 【解説】    以前は text_node_view に 14 と 4 が直書きされていた
// 【解説】 次: lib/src/widget/text_node_view.dart（葉から上に読み上がる）

import 'package:flutter/material.dart';
import 'package:natural_block/natural_block.dart';

/// Visual styling for `NaturalBlockView` and the node views it delegates
/// to (`TextNodeView`, `RowNodeView`, `ColumnNodeView`, ...).
///
/// Maps the semantic concepts the `natural_block` parser produces --
/// [SemanticColor]s and emphasis -- onto concrete [TextStyle]s, and
/// configures how [TextSpanNode.sizeOffset] scales font size.
class NaturalBlockTheme {
  /// The style applied to plain text, i.e. spans with
  /// `color == SemanticColor.none`. Also the style [styleFor] returns for
  /// [SemanticColor.none].
  final TextStyle base;

  /// The style for spans with `color == SemanticColor.danger`.
  final TextStyle danger;

  /// The style for spans with `color == SemanticColor.success`.
  final TextStyle success;

  /// The style for spans with `color == SemanticColor.info`.
  final TextStyle info;

  /// The style merged on top of a span's color style when the span has
  /// `emphasis == true`.
  final TextStyle emphasis;

  /// The style merged on top of a span's color style when the span has
  /// `TextSpanNode.isAction == true` -- i.e. it was written inside `:@...:@`.
  ///
  /// This package never opens URLs, validates them, or otherwise interprets
  /// an actionable span's text; it only renders the span so it *reads* as
  /// tappable and attaches a tap recognizer when a caller supplies
  /// `NaturalBlockView.onActionTap`. Deciding what the tap means -- open a
  /// URL, scroll to a heading, resolve a mention -- is entirely up to the
  /// consuming app.
  final TextStyle action;

  /// The font size used when no ambient [DefaultTextStyle] provides one,
  /// i.e. the fallback base for [TextSpanNode.sizeOffset] scaling.
  final double baseFontSize;

  /// How many logical pixels one step of [TextSpanNode.sizeOffset] adds
  /// (or, for a negative offset, subtracts) from the ambient font size.
  final double fontSizeStep;

  /// The smallest font size [TextSpanNode.sizeOffset] scaling is allowed
  /// to produce. A sufficiently negative `sizeOffset` (the parser accepts
  /// e.g. `:-----`, an offset of -5) would otherwise be able to drive the
  /// computed font size to zero or below, which Flutter asserts on; the
  /// result is clamped to this floor instead.
  final double minFontSize;

  /// Space between a table cell's own edge and its text.
  ///
  /// Not optional in practice: a table sizes its columns to their content,
  /// so without padding the text of neighbouring cells touches. This is
  /// exactly the kind of property a table declaration exists to make
  /// expressible -- the decoration syntax styles text, and has no way to
  /// say anything about the space around it.
  final EdgeInsets tableCellPadding;

  /// Rules drawn around and between a table's rows and columns, or `null`
  /// for none.
  ///
  /// Defaults to hairlines on every edge, outer frame included. A table is
  /// the one construct in this language with a declared beginning and end
  /// (`|~` ... `|~`), so a frame states something the source actually says
  /// -- and it is what separates a table from the prose above and below it
  /// now that the table is sized to its content rather than to the page.
  ///
  /// For rules between cells but no surrounding box, pass
  /// `TableBorder.symmetric(inside: BorderSide(...))`; for no rules at all,
  /// pass `null`.
  final TableBorder? tableBorder;

  /// Background painted on every other row of a table, starting with the
  /// second, or `null` for none.
  ///
  /// Off by default. Striping and rules solve the same problem -- following
  /// one row across the table -- so applying both at once is usually louder
  /// than it is legible; this leaves rules as the default and striping as
  /// the deliberate alternative.
  final Color? tableStripe;

  /// Creates a theme. All fields default to values that keep
  /// `const NaturalBlockTheme()` usable with no [BuildContext] -- see
  /// [NaturalBlockTheme.fromColorScheme] and
  /// [NaturalBlockTheme.fromContext] for context-derived alternatives.
  const NaturalBlockTheme({
    this.base = const TextStyle(),
    this.danger = const TextStyle(color: Colors.red),
    this.success = const TextStyle(color: Colors.green),
    this.info = const TextStyle(color: Colors.blue),
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
    this.tableBorder = const TableBorder.symmetric(
      inside: BorderSide(color: Color(0x1F000000)),
      outside: BorderSide(color: Color(0x1F000000)),
    ),
    this.tableStripe,
  });

  /// Derives a theme from [scheme], keeping the same emphasis style and
  /// font-size scaling as the default constructor but choosing
  /// danger/success/info colors that adapt to the scheme's brightness
  /// (and so, e.g., stay legible in dark mode).
  ///
  /// - [danger] uses [ColorScheme.error], the scheme's own role for
  ///   destructive/alarming content.
  /// - [success] and [info] have no dedicated Material role, so this picks
  ///   [ColorScheme.tertiary] and [ColorScheme.primary] respectively: both
  ///   are guaranteed (by `ColorScheme.fromSeed` and Material's contrast
  ///   requirements) to contrast against the scheme's surface, and using
  ///   two different roles keeps success and info visually distinct from
  ///   each other as well as from primary text.
  /// - [action] also uses [ColorScheme.primary], underlined: `primary` is
  ///   Material's own role for the app's principal interactive color (the
  ///   one buttons and active controls use), so reusing it here makes
  ///   actionable text read as tappable through the same color language the
  ///   rest of a Material app already uses, rather than introducing a
  ///   fourth, unrelated hue. It's the same role [info] uses -- info text
  ///   isn't tappable, so the underline is what actually distinguishes an
  ///   action from merely-informational text; sharing the color is fine.
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
  }) {
    return NaturalBlockTheme(
      base: base,
      danger: TextStyle(color: scheme.error),
      success: TextStyle(color: scheme.tertiary),
      info: TextStyle(color: scheme.primary),
      emphasis: emphasis,
      action: TextStyle(
        color: scheme.primary,
        decoration: TextDecoration.underline,
      ),
      baseFontSize: baseFontSize,
      fontSizeStep: fontSizeStep,
      minFontSize: minFontSize,
      tableCellPadding: tableCellPadding,
      tableBorder: TableBorder.symmetric(
        inside: BorderSide(color: scheme.outlineVariant),
        outside: BorderSide(color: scheme.outlineVariant),
      ),
    );
  }

  /// Convenience for [NaturalBlockTheme.fromColorScheme] using the ambient
  /// `Theme.of(context).colorScheme`.
  ///
  /// Deliberately not named `of`: in Flutter that name means "find this
  /// type on an ancestor" (as `Theme.of` and `MediaQuery.of` do), and
  /// nothing here is provided through an [InheritedWidget]. This builds a
  /// brand-new theme from the ambient [ColorScheme] on every call, so pass
  /// the result down explicitly rather than expecting a lookup.
  factory NaturalBlockTheme.fromContext(BuildContext context) =>
      NaturalBlockTheme.fromColorScheme(Theme.of(context).colorScheme);

  /// Returns the style for [color]; [SemanticColor.none] returns [base].
  TextStyle styleFor(SemanticColor color) => switch (color) {
    SemanticColor.danger => danger,
    SemanticColor.success => success,
    SemanticColor.info => info,
    SemanticColor.none => base,
  };

  /// Returns a copy of this theme with the given fields replaced.
  NaturalBlockTheme copyWith({
    TextStyle? base,
    TextStyle? danger,
    TextStyle? success,
    TextStyle? info,
    TextStyle? emphasis,
    TextStyle? action,
    double? baseFontSize,
    double? fontSizeStep,
    double? minFontSize,
    EdgeInsets? tableCellPadding,
    TableBorder? tableBorder,
    Color? tableStripe,
  }) {
    return NaturalBlockTheme(
      base: base ?? this.base,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      info: info ?? this.info,
      emphasis: emphasis ?? this.emphasis,
      action: action ?? this.action,
      baseFontSize: baseFontSize ?? this.baseFontSize,
      fontSizeStep: fontSizeStep ?? this.fontSizeStep,
      minFontSize: minFontSize ?? this.minFontSize,
      tableCellPadding: tableCellPadding ?? this.tableCellPadding,
      tableBorder: tableBorder ?? this.tableBorder,
      tableStripe: tableStripe ?? this.tableStripe,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NaturalBlockTheme &&
        base == other.base &&
        danger == other.danger &&
        success == other.success &&
        info == other.info &&
        emphasis == other.emphasis &&
        action == other.action &&
        baseFontSize == other.baseFontSize &&
        fontSizeStep == other.fontSizeStep &&
        minFontSize == other.minFontSize &&
        tableCellPadding == other.tableCellPadding &&
        tableBorder == other.tableBorder &&
        tableStripe == other.tableStripe;
  }

  @override
  int get hashCode => Object.hash(
    base,
    danger,
    success,
    info,
    emphasis,
    action,
    baseFontSize,
    fontSizeStep,
    minFontSize,
    tableCellPadding,
    tableBorder,
    tableStripe,
  );
}
