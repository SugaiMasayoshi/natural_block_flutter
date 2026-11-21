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

final _fontHeights = <TextStyle, double>{};

// A line's height with no `height` set, as a multiple of the font size.
double _fontHeightOf(TextStyle style) {
  final font = TextStyle(
    fontFamily: style.fontFamily,
    fontFamilyFallback: style.fontFamilyFallback,
    fontWeight: style.fontWeight,
    fontStyle: style.fontStyle,
    fontSize: 100,
  );
  return _fontHeights.putIfAbsent(font, () {
    final painter = TextPainter(
      text: TextSpan(style: font),
      textDirection: TextDirection.ltr,
    );
    final height = painter.preferredLineHeight / 100;
    painter.dispose();
    return height;
  });
}

/// How natural_block is drawn. The colours it leaves open come from a
/// `ColorScheme` through [resolve], which `NaturalBlockView` does with the
/// ambient one.
class NaturalBlockTheme {
  final TextStyle base;

  /// Drawn over the scheme's error colour.
  final TextStyle negative;

  /// Drawn over a green toned for the scheme's brightness.
  final TextStyle positive;

  final TextStyle emphasis;

  /// Drawn over the scheme's primary colour, underlined.
  final TextStyle custom;

  /// How many times the size around it a run `sizeOffset` steps of `:+` or
  /// `:-` is drawn. A step is 1.2 times by default. A top-level function keeps
  /// the theme `const`, and equal from one build to the next.
  final double Function(int sizeOffset) fontScaleFor;

  final EdgeInsets tableCellPadding;

  /// The rules around and between a table's cells; `const TableBorder()` for
  /// none. Null takes the scheme's outline.
  final TableBorder? tableBorder;

  /// Whether a table bands its rows instead of ruling between them.
  final bool striped;

  /// The band on every other row. Null takes the scheme's when [striped].
  final Color? tableStripe;

  /// By default the first of `monospace`, Menlo, Consolas and Courier New
  /// the platform has, since `monospace` alone is found only on Android and
  /// Linux.
  final TextStyle raw;

  final EdgeInsets rawPadding;

  /// The box around a raw block, whose colour also backs a raw run inside a
  /// line; `const BoxDecoration()` for none. Null takes the scheme's.
  final BoxDecoration? rawDecoration;

  final bool rawScrollsHorizontally;

  const NaturalBlockTheme({
    this.base = const TextStyle(),
    this.negative = const TextStyle(),
    this.positive = const TextStyle(),
    this.emphasis = const TextStyle(fontWeight: FontWeight.bold),
    this.custom = const TextStyle(),
    this.fontScaleFor = _twentyPercentPerStep,
    this.tableCellPadding = const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 4,
    ),
    this.tableBorder,
    this.striped = false,
    this.tableStripe,
    this.raw = const TextStyle(
      fontFamily: 'monospace',
      fontFamilyFallback: ['Menlo', 'Consolas', 'Courier New'],
    ),
    this.rawPadding = const EdgeInsets.all(12),
    this.rawDecoration,
    this.rawScrollsHorizontally = false,
  });

  /// This theme with the colours it leaves open taken from [scheme]. A colour
  /// it sets stays, so resolving twice changes nothing.
  NaturalBlockTheme resolve(ColorScheme scheme) {
    final rule = BorderSide(color: scheme.outlineVariant);
    final green = scheme.brightness == Brightness.light
        ? _positiveLight
        : _positiveDark;
    return copyWith(
      negative: TextStyle(color: scheme.error).merge(negative),
      positive: TextStyle(color: green).merge(positive),
      custom: TextStyle(
        color: scheme.primary,
        decoration: TextDecoration.underline,
      ).merge(custom),
      tableBorder:
          tableBorder ??
          (striped
              ? TableBorder(
                  top: rule,
                  right: rule,
                  bottom: rule,
                  left: rule,
                  verticalInside: rule,
                )
              : TableBorder.symmetric(inside: rule, outside: rule)),
      tableStripe:
          tableStripe ?? (striped ? scheme.surfaceContainerHigh : null),
      rawDecoration:
          rawDecoration ??
          BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
    );
  }

  /// The style one run draws with: [base], then its tone, emphasis and custom
  /// marking, at [baseSize] scaled by [fontScaleFor]. The size comes
  /// only from these: a `fontSize` in the tone, emphasis or custom styles is
  /// not used.
  ///
  /// The space a `height` in [base] adds to the font's own line height stays
  /// the same in pixels at every size, so a large line carries no more space
  /// than a body line, its glyphs never reach into the next line, and a blank
  /// line looks the same next to either.
  TextStyle styleFor(SpanDecoration decoration, {required double baseSize}) {
    final scale = fontScaleFor(decoration.sizeOffset);
    final bodyHeight = base.height;
    final style = base
        .merge(switch (decoration.tone) {
          Tone.negative => negative,
          Tone.positive => positive,
          Tone.none => null,
        })
        .merge(decoration.isEmphasized ? emphasis : null)
        .merge(decoration.isCustom ? custom : null);
    final fontHeight = bodyHeight == null ? 0.0 : _fontHeightOf(style);
    return style.copyWith(
      fontSize: baseSize * scale,
      height: bodyHeight == null
          ? null
          : fontHeight + (bodyHeight - fontHeight) / scale,
    );
  }

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
    bool? striped,
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
    striped: striped ?? this.striped,
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
    striped,
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
