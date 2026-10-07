import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../render/natural_block_actions.dart';
import '../render/natural_block_builders.dart';
import 'natural_block_theme.dart';

/// What a set of spans was built from, so the next [InlineSpans.update] can
/// tell whether they still hold.
typedef _From = ({
  TextNode node,
  NaturalBlockTheme theme,
  TextStyle rootStyle,
  ActionSpanBuilder? buildSpan,
  void Function(String text)? onTap,
});

/// A line's runs as spans, and the recognizers they carry.
///
/// One object because the two cannot outlive each other: a span holds a
/// recognizer, and a recognizer that has taken a pointer down owns an entry
/// in the gesture arena. Replacing the spans without disposing the
/// recognizers leaks them; disposing without replacing leaves spans pointing
/// at dead ones.
///
/// Deciding *when* to rebuild lives here too, next to the reason it matters.
/// Rebuilding replaces the recognizers, and replacing one mid-gesture throws
/// its arena entry away -- the tap then vanishes with no error anywhere.
/// `build` runs for reasons these spans owe nothing to (an ancestor
/// rebuilding, every frame of an animating parent), so the owner calls
/// [update] on each of those and this compares what the spans are made of.
class InlineSpans {
  List<InlineSpan> spans = const [];

  List<TapGestureRecognizer> _recognizers = const [];

  _From? _from;

  /// Rebuilds the spans if what they are made of has changed, and does
  /// nothing if it has not.
  ///
  /// [onTap] is compared like everything else, so hand over something stable
  /// -- a method of the owning state rather than a closure written here.
  /// Dart never considers two closure literals equal, so a fresh one each
  /// time would rebuild every time, and every tap held across a rebuild
  /// would be lost.
  void update(
    BuildContext context,
    TextNode node,
    NaturalBlockScope scope,
    TextStyle rootStyle, {
    required void Function(String text)? onTap,
  }) {
    final from = (
      node: node,
      theme: scope.theme,
      rootStyle: rootStyle,
      buildSpan: scope.actions.buildSpan,
      onTap: onTap,
    );
    if (from == _from) return;
    _from = from;

    dispose();

    final built = <InlineSpan>[];
    final taken = <TapGestureRecognizer>[];
    for (final child in node.children) {
      switch (child) {
        case RawSpanNode():
          built.add(_rawSpan(context, child, scope.theme));
        case TextSpanNode():
          final (span, recognizer) = _textSpan(
            context,
            child,
            scope,
            rootStyle,
            onTap,
          );
          built.add(span);
          if (recognizer != null) taken.add(recognizer);
      }
    }
    spans = built;
    _recognizers = taken;
  }

  /// Releases the recognizers the current spans carry.
  ///
  /// Safe to call twice: the list is emptied, so a later call from the
  /// owner's own `dispose` has nothing left to release.
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers = const [];
  }
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
