import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../render/natural_block_actions.dart';
import 'natural_block_theme.dart';

/// Everything a line's spans are made of.
///
/// One value, because it is both what the spans are built from and what
/// decides whether the ones already built still hold. Two values could
/// disagree -- something could reach the building without reaching the
/// comparison, and then a change would never redraw.
///
/// The `BuildContext` is deliberately not in here: it is not something to
/// compare, and the spans are rebuilt when what it carries changes by way of
/// `rootStyle`.
typedef SpanInputs = ({
  TextNode node,
  NaturalBlockTheme theme,

  /// What the line starts from, and the size a `:+` counts from.
  TextStyle rootStyle,
  ActionSpanBuilder? buildSpan,

  /// Null when nothing is wired to a tap, which is also what decides whether
  /// a run is tappable at all.
  void Function(String text)? onTap,
});

/// A span that owns the recognizer it carries.
///
/// The type is the ownership: a span handed back by `SpanInputs.buildSpan`
/// may carry a recognizer of the caller's own, and disposing that one would
/// break something this package does not own. Only the spans made here are
/// this kind, so only these are ever released.
class ActionSpan extends TextSpan {
  const ActionSpan({
    required String super.text,
    super.style,
    required TapGestureRecognizer super.recognizer,
    super.semanticsLabel,
  });

  void dispose() => (recognizer! as TapGestureRecognizer).dispose();
}

/// The span for one run: the style its decoration asks the theme for, or
/// whatever `SpanInputs.buildSpan` returned in its place.
InlineSpan runSpan(BuildContext context, InlineNode node, SpanInputs from) =>
    switch (node) {
      RawSpanNode() => _raw(context, node, from),
      TextSpanNode() => _styled(context, node, from),
    };

/// A raw run is text the parser stopped reading, so the only thing to do is
/// not undo that: the ambient style, made monospaced.
InlineSpan _raw(BuildContext context, RawSpanNode run, SpanInputs from) =>
    TextSpan(
      text: run.text,
      style: DefaultTextStyle.of(context).style.merge(from.theme.raw),
    );

InlineSpan _styled(BuildContext context, TextSpanNode run, SpanInputs from) {
  final theme = from.theme;
  final baseSize = from.rootStyle.fontSize ?? theme.baseFontSize;
  final style = theme.styleFor(run.decoration, baseSize: baseSize);

  if (run.decoration.isAction) {
    final built = from.buildSpan?.call(
      context,
      run.text,
      // The replacement is given a size to work from, never an unstated one.
      style.copyWith(fontSize: style.fontSize ?? baseSize),
      theme,
    );
    if (built != null) return built;
  }

  final onTap = from.onTap;
  if (!run.decoration.isAction || onTap == null) {
    return TextSpan(text: run.text, style: style);
  }

  final text = run.text;
  return ActionSpan(
    text: text,
    style: style,
    recognizer: TapGestureRecognizer()..onTap = () => onTap(text),
    // Announced to a screen reader only because something answers the tap.
    semanticsLabel: text,
  );
}
