import 'dart:math' show max;

import 'package:flutter/foundation.dart';
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

  /// A theme whose colours come from [scheme], and whose everything else is
  /// the default constructor's.
  ///
  /// Only what a `ColorScheme` can answer is named here. Changing anything
  /// else is `copyWith`'s job.
  factory NaturalBlockTheme.fromColorScheme(
    ColorScheme scheme, {
    bool striped = false,
  }) {
    final rule = BorderSide(color: scheme.outlineVariant);
    return NaturalBlockTheme(
      negative: TextStyle(color: scheme.error),
      positive: TextStyle(color: scheme.tertiary),
      action: TextStyle(
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

  /// A theme derived from the ambient `ThemeData`: its colours from the
  /// `ColorScheme`, and the size a `:+` counts from its body text.
  ///
  /// `bodyMedium` is Material's own "ordinary text", so a document reads at
  /// the size the rest of the app does, and nothing here restates a number
  /// Material already decided. Null leaves [baseFontSize] alone, the way
  /// every other omitted [copyWith] argument does.
  factory NaturalBlockTheme.fromContext(
    BuildContext context, {
    bool striped = false,
  }) {
    final theme = Theme.of(context);
    return NaturalBlockTheme.fromColorScheme(
      theme.colorScheme,
      striped: striped,
    ).copyWith(baseFontSize: theme.textTheme.bodyMedium?.fontSize);
  }

  /// What one run's decoration looks like: the tone's style, with emphasis
  /// and actionability laid over it, at the size its `:+` and `:-` ask for.
  ///
  /// The whole mapping from what the source said to what is drawn, in the one
  /// place that holds every value it needs. [baseSize] is what the sizes
  /// count from -- the ambient size, or [baseFontSize] where nothing ambient
  /// names one -- and is the only thing here that comes from outside.
  TextStyle styleFor(SpanDecoration decoration, {required double baseSize}) =>
      switch (decoration.tone) {
            Tone.negative => negative,
            Tone.positive => positive,
            Tone.none => base,
          }
          .merge(decoration.emphasis ? emphasis : null)
          .merge(decoration.isAction ? action : null)
          .copyWith(
            // Left unstated when the source asked for no step, so the run
            // keeps whatever size it would have drawn at anyway.
            // Clamped, so no number of `:-` can reach zero or go negative.
            fontSize: decoration.sizeOffset == 0
                ? null
                : max(
                    minFontSize,
                    baseSize + decoration.sizeOffset * fontSizeStep,
                  ),
          );

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

  /// Every field, in one list, so equality and the hash cannot disagree about
  /// what this theme is made of. Listing them twice let a field reach one and
  /// not the other, which makes two unequal themes hash alike.
  List<Object?> get _fields => [
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
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NaturalBlockTheme && listEquals(_fields, other._fields);

  @override
  int get hashCode => Object.hashAll(_fields);
}
