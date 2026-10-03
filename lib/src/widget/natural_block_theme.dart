import 'package:flutter/material.dart';
import 'package:natural_block/natural_block.dart';

class NaturalBlockTheme {
  final TextStyle base;

  final TextStyle negative;

  final TextStyle positive;

  final TextStyle emphasis;

  final TextStyle action;

  final double baseFontSize;

  final double fontSizeStep;

  final double minFontSize;

  final EdgeInsets tableCellPadding;

  /// The rules drawn around and between a table's rows and columns.
  ///
  /// Not nullable, because the type already says "none": every side of a
  /// `const TableBorder()` defaults to `BorderSide.none`, which draws nothing
  /// and measures the same as no border at all. Writing none as a value
  /// rather than as null is what lets `copyWith` below stay plain.
  final TableBorder tableBorder;

  /// A background painted on every other row, or null for none.
  ///
  /// The one field here where null earns its keep. `Color` has no "none" of
  /// its own, and a transparent one is still a fill: it would put a
  /// `BoxDecoration` on every other row of every table, where null leaves
  /// `TableRow.decoration` off entirely. Flutter types that field the same
  /// way, and for the same reason.
  final Color? tableStripe;

  final TextStyle raw;

  final EdgeInsets rawPadding;

  /// The box drawn around a raw block.
  ///
  /// Not nullable for the same reason as [tableBorder]: a
  /// `const BoxDecoration()` names no colour, border or shadow, so it draws
  /// nothing. It costs one inert `DecoratedBox` per raw block, which buys a
  /// `copyWith` with no sentinel in it.
  final BoxDecoration rawDecoration;

  final bool rawScrollsHorizontally;

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
      rawDecoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
    );
  }

  factory NaturalBlockTheme.fromContext(
    BuildContext context, {
    bool striped = false,
  }) => NaturalBlockTheme.fromColorScheme(
    Theme.of(context).colorScheme,
    striped: striped,
  );

  TextStyle styleFor(Tone tone) => switch (tone) {
    Tone.negative => negative,
    Tone.positive => positive,
    Tone.none => base,
  };

  /// This theme with the given fields replaced.
  ///
  /// Every argument means "leave this alone" when omitted, the way Flutter's
  /// own `copyWith` methods do. None of them can set a field *to* null, and
  /// none needs to: "no rules" is `const TableBorder()`, "no box" is
  /// `const BoxDecoration()`, and a theme without stripes is what
  /// [NaturalBlockTheme.fromColorScheme] gives you unless you ask for them.
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
    TableBorder? tableBorder,
    Color? tableStripe,
    TextStyle? raw,
    EdgeInsets? rawPadding,
    BoxDecoration? rawDecoration,
    bool? rawScrollsHorizontally,
  }) => NaturalBlockTheme(
    base: base ?? this.base,
    negative: negative ?? this.negative,
    positive: positive ?? this.positive,
    emphasis: emphasis ?? this.emphasis,
    action: action ?? this.action,
    baseFontSize: baseFontSize ?? this.baseFontSize,
    fontSizeStep: fontSizeStep ?? this.fontSizeStep,
    minFontSize: minFontSize ?? this.minFontSize,
    tableCellPadding: tableCellPadding ?? this.tableCellPadding,
    tableBorder: tableBorder ?? this.tableBorder,
    tableStripe: tableStripe ?? this.tableStripe,
    raw: raw ?? this.raw,
    rawPadding: rawPadding ?? this.rawPadding,
    rawDecoration: rawDecoration ?? this.rawDecoration,
    rawScrollsHorizontally:
        rawScrollsHorizontally ?? this.rawScrollsHorizontally,
  );

  @override
  bool operator ==(Object other) {
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
