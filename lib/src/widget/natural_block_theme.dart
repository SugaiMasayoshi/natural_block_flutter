import 'package:flutter/material.dart';
import 'package:natural_block/natural_block.dart';

class NaturalBlockTheme {
  final TextStyle base;

  final TextStyle danger;

  final TextStyle success;

  final TextStyle emphasis;

  final TextStyle action;

  final double baseFontSize;

  final double fontSizeStep;

  final double minFontSize;

  final EdgeInsets tableCellPadding;

  final TableBorder? tableBorder;

  final Color? tableStripe;

  final TextStyle verbatim;

  final EdgeInsets verbatimPadding;

  final BoxDecoration? verbatimDecoration;

  final bool verbatimScrollsHorizontally;

  const NaturalBlockTheme({
    this.base = const TextStyle(),
    this.danger = const TextStyle(color: Colors.red),
    this.success = const TextStyle(color: Colors.green),
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
    this.verbatim = const TextStyle(fontFamily: 'monospace'),
    this.verbatimPadding = const EdgeInsets.all(12),
    this.verbatimDecoration = const BoxDecoration(
      color: Color(0x0A000000),
      borderRadius: BorderRadius.all(Radius.circular(4)),
    ),
    this.verbatimScrollsHorizontally = false,
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
      danger: TextStyle(color: scheme.error),
      success: TextStyle(color: scheme.tertiary),
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
    );
  }

  factory NaturalBlockTheme.fromContext(
    BuildContext context, {
    bool striped = false,
  }) => NaturalBlockTheme.fromColorScheme(
    Theme.of(context).colorScheme,
    striped: striped,
  );

  TextStyle styleFor(SemanticColor color) => switch (color) {
    SemanticColor.danger => danger,
    SemanticColor.success => success,
    SemanticColor.none => base,
  };

  static const Object _unchanged = Object();

  NaturalBlockTheme copyWith({
    TextStyle? base,
    TextStyle? danger,
    TextStyle? success,
    TextStyle? emphasis,
    TextStyle? action,
    double? baseFontSize,
    double? fontSizeStep,
    double? minFontSize,
    EdgeInsets? tableCellPadding,
    Object? tableBorder = _unchanged,
    Object? tableStripe = _unchanged,
    TextStyle? verbatim,
    EdgeInsets? verbatimPadding,
    Object? verbatimDecoration = _unchanged,
    bool? verbatimScrollsHorizontally,
  }) {
    assert(
      tableBorder == _unchanged || tableBorder is TableBorder?,
      'tableBorder must be a TableBorder or null',
    );
    assert(
      tableStripe == _unchanged || tableStripe is Color?,
      'tableStripe must be a Color or null',
    );
    assert(
      verbatimDecoration == _unchanged || verbatimDecoration is BoxDecoration?,
      'verbatimDecoration must be a BoxDecoration or null',
    );
    return NaturalBlockTheme(
      base: base ?? this.base,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      emphasis: emphasis ?? this.emphasis,
      action: action ?? this.action,
      baseFontSize: baseFontSize ?? this.baseFontSize,
      fontSizeStep: fontSizeStep ?? this.fontSizeStep,
      minFontSize: minFontSize ?? this.minFontSize,
      tableCellPadding: tableCellPadding ?? this.tableCellPadding,
      tableBorder: identical(tableBorder, _unchanged)
          ? this.tableBorder
          : tableBorder as TableBorder?,
      tableStripe: identical(tableStripe, _unchanged)
          ? this.tableStripe
          : tableStripe as Color?,
      verbatim: verbatim ?? this.verbatim,
      verbatimPadding: verbatimPadding ?? this.verbatimPadding,
      verbatimDecoration: identical(verbatimDecoration, _unchanged)
          ? this.verbatimDecoration
          : verbatimDecoration as BoxDecoration?,
      verbatimScrollsHorizontally:
          verbatimScrollsHorizontally ?? this.verbatimScrollsHorizontally,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NaturalBlockTheme &&
        base == other.base &&
        danger == other.danger &&
        success == other.success &&
        emphasis == other.emphasis &&
        action == other.action &&
        baseFontSize == other.baseFontSize &&
        fontSizeStep == other.fontSizeStep &&
        minFontSize == other.minFontSize &&
        tableCellPadding == other.tableCellPadding &&
        tableBorder == other.tableBorder &&
        tableStripe == other.tableStripe &&
        verbatim == other.verbatim &&
        verbatimPadding == other.verbatimPadding &&
        verbatimDecoration == other.verbatimDecoration &&
        verbatimScrollsHorizontally == other.verbatimScrollsHorizontally;
  }

  @override
  int get hashCode => Object.hash(
    base,
    danger,
    success,
    emphasis,
    action,
    baseFontSize,
    fontSizeStep,
    minFontSize,
    tableCellPadding,
    tableBorder,
    tableStripe,
    verbatim,
    verbatimPadding,
    verbatimDecoration,
    verbatimScrollsHorizontally,
  );
}
