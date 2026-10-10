import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../render/run_handler.dart';
import 'natural_block_theme.dart';

/// Everything a line's spans are made of.
///
/// One value, because it is both what the spans are built from and what
/// decides whether the ones already built still hold. Two values could
/// disagree -- something could reach the building without reaching the
/// comparison, and then a change would never redraw.
typedef SpanInputs = ({
  TextNode line,
  NaturalBlockTheme theme,

  /// What every run of the line starts from, and the size a `:+` counts
  /// from: the ambient style with the theme's `base` over it.
  ///
  /// Resolved by the owner rather than read from a `BuildContext` down here,
  /// because whatever is read has to be part of what the spans are compared
  /// by. Reading the ambient style in both places is what let an ambient
  /// change reach the drawing without reaching the comparison.
  TextStyle rootStyle,
  List<RunHandler> customs,

  /// Null when nothing is wired to a tap. Stable across builds, so that a
  /// caller writing a fresh callback each time does not cost a redraw.
  OnActionTap? onTap,
});

/// A line's runs as spans, each with what releasing it takes.
List<RunRendering> runSpans(SpanInputs from) {
  final runs = from.line.children;
  return List.generate(runs.length, (i) => _runSpan(runs[i], from));
}

RunRendering _runSpan(InlineNode run, SpanInputs from) {
  switch (run) {
    // A raw run is text the parser stopped reading, so the only thing to do
    // is not undo that: what the line is drawn in, made monospaced.
    case RawSpanNode():
      return (
        span: TextSpan(
          text: run.text,
          style: from.rootStyle.merge(from.theme.raw),
        ),
        dispose: () {},
      );

    case TextSpanNode():
      final theme = from.theme;
      final text = run.text;
      final baseSize = from.rootStyle.fontSize ?? theme.baseFontSize;
      final style = theme.styleFor(run.decoration, baseSize: baseSize);

      // `styleFor` leaves the size unstated where the source asked for no
      // step, so this is what the run actually draws at.
      final drawnSize = style.fontSize ?? baseSize;

      // Styled as actionable either way. What the handlers decide is how it
      // is drawn and whether it answers a tap.
      final claimed = run.decoration.isAction
          ? _claim(from, text, style.copyWith(fontSize: drawnSize))
          : null;

      return claimed ??
          (span: TextSpan(text: text, style: style), dispose: () {});
  }
}

/// The first handler to draw [text] itself, or null when none of them does.
///
/// [style] carries a real size rather than an unstated one, so a handler has
/// something to work from.
RunRendering? _claim(SpanInputs from, String text, TextStyle style) {
  final onTap = from.onTap;

  for (final handler in from.customs) {
    final rendering = handler(
      text,
      style,
      from.theme,
      onTap == null ? null : () => onTap(text),
    );
    if (rendering != null) return rendering;
  }
  return null;
}
