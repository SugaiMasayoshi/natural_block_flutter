import 'dart:math' show pow;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:natural_block/natural_block.dart';

// Green, toned for each brightness the way a scheme tones its error.
final _positiveLight = ColorScheme.fromSeed(seedColor: Colors.green).primary;
final _positiveDark = ColorScheme.fromSeed(
  seedColor: Colors.green,
  brightness: Brightness.dark,
).primary;

class NaturalBlockTheme {
  final TextStyle base;

  final TextStyle negative;

  final TextStyle positive;

  final TextStyle emphasis;

  final TextStyle custom;

  /// How many times the size around it a run `sizeOffset` steps of `:+` or
  /// `:-` is drawn. A step is 1.2 times by default. A top-level function keeps
  /// the theme `const`, and equal from one build to the next.
  final double Function(int sizeOffset) fontScaleFor;

  final EdgeInsets tableCellPadding;

  /// The rules around and between a table's cells; `const TableBorder()` for none.
  final TableBorder tableBorder;

  /// A background on every other row, or null for none.
  final Color? tableStripe;

  final TextStyle raw;

  final EdgeInsets rawPadding;

  /// The box around a raw block; `const BoxDecoration()` for none.
  final BoxDecoration rawDecoration;

  final bool rawScrollsHorizontally;

  const NaturalBlockTheme({
    this.base = const TextStyle(),
    this.negative = const TextStyle(color: Colors.red),
    this.positive = const TextStyle(color: Colors.green),
    this.emphasis = const TextStyle(fontWeight: FontWeight.bold),
    this.custom = const TextStyle(
      color: Colors.blue,
      decoration: TextDecoration.underline,
    ),
    this.fontScaleFor = _twentyPercentPerStep,
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

  /// A theme whose colours come from [scheme]; everything else is the default's.
  factory NaturalBlockTheme.fromColorScheme(
    ColorScheme scheme, {
    bool striped = false,
  }) {
    final rule = BorderSide(color: scheme.outlineVariant);
    return NaturalBlockTheme(
      negative: TextStyle(color: scheme.error),
      positive: TextStyle(
        color: scheme.brightness == Brightness.light
            ? _positiveLight
            : _positiveDark,
      ),
      custom: TextStyle(
        color: scheme.primary,
        decoration: TextDecoration.underline,
      ),
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

  /// A theme whose colours come from the ambient `ThemeData`.
  factory NaturalBlockTheme.fromContext(
    BuildContext context, {
    bool striped = false,
  }) {
    return NaturalBlockTheme.fromColorScheme(
      Theme.of(context).colorScheme,
      striped: striped,
    );
  }

  /// The style one run draws with: [base], then its tone, emphasis and custom
  /// marking, at [baseSize] scaled by [fontScaleFor]. The size comes
  /// only from these: a `fontSize` in the tone, emphasis or custom styles is
  /// not used.
  TextStyle styleFor(SpanDecoration decoration, {required double baseSize}) =>
      base
          .merge(switch (decoration.tone) {
            Tone.negative => negative,
            Tone.positive => positive,
            Tone.none => null,
          })
          .merge(decoration.isEmphasized ? emphasis : null)
          .merge(decoration.isCustom ? custom : null)
          .copyWith(fontSize: baseSize * fontScaleFor(decoration.sizeOffset));

  /// This theme with the given fields replaced. An omitted argument keeps the
  /// current value; none can set a field to null.
  NaturalBlockTheme copyWith({
    TextStyle? base,
    TextStyle? negative,
    TextStyle? positive,
    TextStyle? emphasis,
    TextStyle? custom,
    double Function(int sizeOffset)? fontScaleFor,
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
    custom: custom ?? this.custom,
    fontScaleFor: fontScaleFor ?? this.fontScaleFor,
    tableCellPadding: tableCellPadding ?? this.tableCellPadding,
    tableBorder: tableBorder ?? this.tableBorder,
    tableStripe: tableStripe ?? this.tableStripe,
    raw: raw ?? this.raw,
    rawPadding: rawPadding ?? this.rawPadding,
    rawDecoration: rawDecoration ?? this.rawDecoration,
    rawScrollsHorizontally:
        rawScrollsHorizontally ?? this.rawScrollsHorizontally,
  );

  List<Object?> get _fields => [
    base,
    negative,
    positive,
    emphasis,
    custom,
    fontScaleFor,
    tableCellPadding,
    tableBorder,
    tableStripe,
    raw,
    rawPadding,
    rawDecoration,
    rawScrollsHorizontally,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NaturalBlockTheme && listEquals(_fields, other._fields);

  @override
  int get hashCode => Object.hashAll(_fields);
}

double _twentyPercentPerStep(int sizeOffset) => pow(1.2, sizeOffset).toDouble();
