import 'package:flutter/gestures.dart';
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

/// A span that owns the recognizer it carries.
///
/// The type is the ownership. A `SpanRun` handed back by a handler may carry
/// a recognizer of the app's own, and disposing that one would break
/// something this package does not own. Only the spans made here are this
/// kind, so only these are ever released.
class TappableSpan extends TextSpan {
  const TappableSpan({
    required String super.text,
    super.style,
    required TapGestureRecognizer super.recognizer,
    super.semanticsLabel,
  });

  void dispose() => (recognizer! as TapGestureRecognizer).dispose();
}

/// The span for one run.
InlineSpan runSpan(BuildContext context, InlineNode node, SpanInputs from) {
  switch (node) {
    // A raw run is text the parser stopped reading, so the only thing to do
    // is not undo that: the ambient style, made monospaced.
    case RawSpanNode():
      return TextSpan(
        text: node.text,
        style: DefaultTextStyle.of(context).style.merge(from.theme.raw),
      );

    case TextSpanNode():
      final theme = from.theme;
      final text = node.text;
      final baseSize = from.rootStyle.fontSize ?? theme.baseFontSize;
      final style = theme.styleFor(node.decoration, baseSize: baseSize);

      // Styled as actionable either way. What the handlers decide is how it
      // is drawn and whether it answers a tap.
      if (!node.decoration.isAction) return TextSpan(text: text, style: style);

      final onTap = from.onTap;
      final rendering = _ask(
        from.customs,
        context,
        text,
        // Handlers are given a size to work from, never an unstated one.
        style.copyWith(fontSize: style.fontSize ?? baseSize),
        theme,
        onTap == null ? null : () => onTap(text),
      );

      return switch (rendering) {
        null => TextSpan(text: text, style: style),
        SpanRun(:final span) => span,
        WidgetRun(:final child, :final alignment) => WidgetSpan(
          alignment: alignment,
          child: child,
        ),
        TextRun(text: final given, style: final asked, :final onTap) =>
          _textRun(given ?? text, asked ?? style, onTap),
      };
  }
}

/// The first answer the handlers give, or null when none of them claims the
/// run.
RunRendering? _ask(
  List<RunHandler> customs,
  BuildContext context,
  String text,
  TextStyle style,
  NaturalBlockTheme theme,
  VoidCallback? onTap,
) {
  for (final handler in customs) {
    final rendering = handler(context, text, style, theme, onTap);
    if (rendering != null) return rendering;
  }
  return null;
}

/// A text run, tappable when something answers it.
///
/// Announced to a screen reader only then, because claiming interactivity
/// that nothing answers is a promise this package cannot keep.
InlineSpan _textRun(String text, TextStyle style, VoidCallback? onTap) =>
    onTap == null
    ? TextSpan(text: text, style: style)
    : TappableSpan(
        text: text,
        style: style,
        recognizer: TapGestureRecognizer()..onTap = onTap,
        semanticsLabel: text,
      );
