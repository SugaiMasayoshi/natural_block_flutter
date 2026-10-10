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
///
/// `customs` is compared as a list, so hand over a stable one: a `const` list
/// of named handlers compares equal across builds, where one written out
/// afresh in a `build` never does. Writing it afresh costs a redraw of every
/// line, and a tap held across that redraw is lost.
///
/// The `BuildContext` is deliberately not in here: it is not something to
/// compare, and the spans are rebuilt when what it carries changes by way of
/// `rootStyle`.
typedef SpanInputs = ({
  TextNode node,
  NaturalBlockTheme theme,

  /// What the line starts from, and the size a `:+` counts from.
  TextStyle rootStyle,
  List<RunHandler> customs,

  /// Null when nothing is wired to a tap. Stable across builds, so that a
  /// caller writing a fresh callback each time does not cost a redraw.
  OnActionTap? onTap,
});

/// The span for one run, and what releasing it takes.
RunRendering runSpan(BuildContext context, InlineNode node, SpanInputs from) {
  switch (node) {
    // A raw run is text the parser stopped reading, so the only thing to do
    // is not undo that: the ambient style, made monospaced.
    case RawSpanNode():
      return (
        span: TextSpan(
          text: node.text,
          style: DefaultTextStyle.of(context).style.merge(from.theme.raw),
        ),
        dispose: () {},
      );

    case TextSpanNode():
      final theme = from.theme;
      final text = node.text;
      final baseSize = from.rootStyle.fontSize ?? theme.baseFontSize;
      final style = theme.styleFor(node.decoration, baseSize: baseSize);

      // Styled as actionable either way. What the handlers decide is how it
      // is drawn and whether it answers a tap -- and a run one of them
      // claims never reaches the plain span below.
      if (node.decoration.isAction) {
        final onTap = from.onTap;
        for (final handler in from.customs) {
          final rendering = handler(
            context,
            text,
            // Handlers are given a size to work from, never an unstated one.
            style.copyWith(fontSize: style.fontSize ?? baseSize),
            theme,
            onTap == null ? null : () => onTap(text),
          );
          if (rendering != null) return rendering;
        }
      }

      return (span: TextSpan(text: text, style: style), dispose: () {});
  }
}
