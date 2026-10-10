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

/// A line's runs as spans, and whatever any of them left to release.
///
/// Only a run some handler claimed leaves anything, so a line of ordinary
/// text has nothing to release at all. Which `dispose` came from which span
/// is never asked, which is why they are two lists rather than one list of
/// pairs, and why the second is usually shorter than the first.
({List<InlineSpan> spans, List<VoidCallback> disposes}) runSpans(
  SpanInputs from,
) {
  final theme = from.theme;
  final runs = from.line.children;

  // One span per run, so the length is known; every arm below fills its own
  // index and the switch is exhaustive, so no slot keeps the placeholder.
  final spans = List<InlineSpan>.filled(runs.length, const TextSpan());
  final disposes = <VoidCallback>[];

  for (var i = 0; i < runs.length; i++) {
    final run = runs[i];
    switch (run) {
      // A raw run is text the parser stopped reading, so the only thing to
      // do is not undo that: what the line is drawn in, made monospaced.
      case RawSpanNode():
        spans[i] = TextSpan(
          text: run.text,
          style: from.rootStyle.merge(theme.raw),
        );

      case TextSpanNode():
        final text = run.text;
        final baseSize = from.rootStyle.fontSize ?? theme.baseFontSize;
        final style = theme.styleFor(run.decoration, baseSize: baseSize);

        // `styleFor` leaves the size unstated where the source asked for no
        // step, so this is what the run actually draws at.
        final drawnSize = style.fontSize ?? baseSize;

        // Styled as actionable either way. What the handlers decide is how
        // it is drawn and whether it answers a tap.
        final claimed = run.decoration.isAction
            ? _claim(from, text, style.copyWith(fontSize: drawnSize))
            : null;

        spans[i] = claimed?.span ?? TextSpan(text: text, style: style);
        if (claimed != null) disposes.add(claimed.dispose);
    }
  }

  return (spans: spans, disposes: disposes);
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
