import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../render/natural_block_builders.dart';
import 'natural_block_theme.dart';

/// The spans for a line's runs, and the recognizers they carry.
///
/// The recognizers are handed back rather than kept: one that has taken a
/// pointer down owns an entry in the gesture arena, so whoever keeps the
/// spans has to be the one that disposes them.
({List<InlineSpan> spans, List<TapGestureRecognizer> recognizers})
buildInlineSpans(
  BuildContext context,
  TextNode node,
  NaturalBlockScope scope,
  TextStyle rootStyle, {
  required void Function(String text)? onTap,
}) {
  final spans = <InlineSpan>[];
  final recognizers = <TapGestureRecognizer>[];

  for (final child in node.children) {
    switch (child) {
      case RawSpanNode():
        spans.add(_rawSpan(context, child, scope.theme));
      case TextSpanNode():
        final (span, recognizer) = _textSpan(
          context,
          child,
          scope,
          rootStyle,
          onTap,
        );
        spans.add(span);
        if (recognizer != null) recognizers.add(recognizer);
    }
  }

  return (spans: spans, recognizers: recognizers);
}

InlineSpan _rawSpan(
  BuildContext context,
  RawSpanNode node,
  NaturalBlockTheme theme,
) => TextSpan(
  text: node.text,
  style: DefaultTextStyle.of(context).style.merge(theme.raw),
);

/// The span for one styled run, or whatever `actions.buildSpan` returned for
/// it, and the recognizer it took if it is tappable.
(InlineSpan, TapGestureRecognizer?) _textSpan(
  BuildContext context,
  TextSpanNode span,
  NaturalBlockScope scope,
  TextStyle rootStyle,
  void Function(String text)? onTap,
) {
  final theme = scope.theme;
  final actions = scope.actions;
  final style = theme
      .styleFor(span.decoration.tone)
      .merge(span.decoration.emphasis ? theme.emphasis : null)
      .merge(span.decoration.isAction ? theme.action : null)
      .copyWith(
        fontSize: span.decoration.sizeOffset != 0
            ? _fontSizeFor(span.decoration.sizeOffset, theme, rootStyle)
            : null,
      );

  if (span.decoration.isAction) {
    final built = actions.buildSpan?.call(
      context,
      span.text,
      style.copyWith(
        fontSize: style.fontSize ?? _baseFontSize(theme, rootStyle),
      ),
      theme,
    );
    if (built != null) return (built, null);
  }

  if (!span.decoration.isAction || onTap == null) {
    return (TextSpan(text: span.text, style: style), null);
  }

  final text = span.text;
  final recognizer = TapGestureRecognizer()..onTap = () => onTap(text);
  return (
    TextSpan(
      text: text,
      style: style,
      recognizer: recognizer,
      semanticsLabel: text,
    ),
    recognizer,
  );
}

/// The size a run of this line draws at before any `:+` or `:-`.
double _baseFontSize(NaturalBlockTheme theme, TextStyle rootStyle) =>
    rootStyle.fontSize ?? theme.baseFontSize;

double _fontSizeFor(
  int sizeOffset,
  NaturalBlockTheme theme,
  TextStyle rootStyle,
) {
  final scaled =
      _baseFontSize(theme, rootStyle) + sizeOffset * theme.fontSizeStep;
  return scaled < theme.minFontSize ? theme.minFontSize : scaled;
}
