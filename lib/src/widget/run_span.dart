import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../render/natural_block_builders.dart';

/// A span that owns the recognizer it carries.
///
/// The type is the ownership: a span handed back by `actions.buildSpan` may
/// carry a recognizer of the caller's own, and disposing that one would break
/// something this package does not own. Only the spans made here are this
/// kind, so only these are ever released.
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
/// whatever `actions.buildSpan` returned in its place.
///
/// [rootStyle] is what the line starts from, and the size a `:+` counts from.
/// [onTap] is null when the run is not tappable or nothing is wired to it.
InlineSpan runSpan(
  BuildContext context,
  InlineNode node,
  NaturalBlockScope scope,
  TextStyle rootStyle, {
  required void Function(String text)? onTap,
}) => switch (node) {
  RawSpanNode() => TextSpan(
    text: node.text,
    style: DefaultTextStyle.of(context).style.merge(scope.theme.raw),
  ),
  TextSpanNode() => _styled(context, node, scope, rootStyle, onTap),
};

InlineSpan _styled(
  BuildContext context,
  TextSpanNode run,
  NaturalBlockScope scope,
  TextStyle rootStyle,
  void Function(String text)? onTap,
) {
  final theme = scope.theme;
  final baseSize = rootStyle.fontSize ?? theme.baseFontSize;
  final style = theme.styleFor(run.decoration, baseSize: baseSize);

  if (run.decoration.isAction) {
    final built = scope.actions.buildSpan?.call(
      context,
      run.text,
      // The replacement is given a size to work from, never an unstated one.
      style.copyWith(fontSize: style.fontSize ?? baseSize),
      theme,
    );
    if (built != null) return built;
  }

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
