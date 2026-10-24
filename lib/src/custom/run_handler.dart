import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../widget/natural_block_theme.dart';

/// How one custom run is drawn: the span to put in the line, and what to
/// release when the line is rebuilt or goes away.
///
/// Whatever the `span` carries, a gesture recognizer included, is yours, and
/// `dispose` is the only thing that releases it. It is required so that having
/// nothing to release is written -- `() {}` -- not forgotten.
typedef RunRendering = ({InlineSpan span, VoidCallback dispose});

/// A run drawn as [child] rather than as text.
///
/// [alignment] defaults to `middle`, not `WidgetSpan`'s `bottom`, so the box
/// is centred on the text beside it. There is nothing to release: Flutter
/// disposes what is inside a `WidgetSpan`.
///
/// [child] is one unbreakable box and will not wrap; return a `TextSpan` of
/// your own for anything that should.
RunRendering widgetRun(
  Widget child, {
  PlaceholderAlignment alignment = PlaceholderAlignment.middle,
}) => (span: WidgetSpan(alignment: alignment, child: child), dispose: () {});

/// One custom run as a handler receives it: its own `text`, the `style` it
/// would have been drawn with (`fontSize` always resolved), the `decoration`
/// the source gave it, and `withContext`, which calls an action with the
/// line's `BuildContext` -- for later, such as a tap, not while drawing.
typedef CustomRun = ({
  String text,
  TextStyle style,
  NaturalBlockTheme theme,
  SpanDecoration decoration,
  void Function(void Function(BuildContext context) action) withContext,
});

/// Answers how [run] is drawn, or null to leave it to the next handler.
typedef RunHandler = RunRendering? Function(CustomRun run);

/// [run] drawn as tappable text, which is what a URL wants. A tap calls
/// [onTap] with the line's `BuildContext`, current when the tap happens:
///
/// ```dart
/// RunRendering? links(CustomRun run) => tappableText(
///   run,
///   onTap: (context) => openUrl(context, run.text),
/// );
/// ```
RunRendering tappableText(
  CustomRun run, {
  required void Function(BuildContext context) onTap,
}) {
  final recognizer = TapGestureRecognizer()
    ..onTap = () => run.withContext(onTap);
  return (
    span: TextSpan(
      text: run.text,
      style: run.style,
      recognizer: recognizer,
      semanticsLabel: run.text,
    ),
    dispose: recognizer.dispose,
  );
}
