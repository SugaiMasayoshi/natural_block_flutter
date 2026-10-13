import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../widget/natural_block_theme.dart';

/// What tapping a custom run means. Receives the run's own text; nothing here
/// interprets it.
typedef OnCustomTap = void Function(String text);

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

/// Answers how one custom run is drawn, or null to leave it to the next
/// handler. [style] is what the run would have been drawn with, its
/// `fontSize` always resolved.
typedef RunHandler = RunRendering? Function(
  String text,
  TextStyle style,
  NaturalBlockTheme theme,
);

/// [text] drawn as tappable text, which is what a URL wants.
///
/// Not a [RunHandler] itself: [onTap] says what a tap means, so a handler of
/// your own supplies it --
///
/// ```dart
/// RunRendering? links(String text, TextStyle style, NaturalBlockTheme theme) =>
///     tappableText(text, style, onTap: openUrl);
/// ```
///
/// -- and passes something that reads the current callback when it is
/// called, such as a method of your state. [onTap] is captured when the run
/// is drawn and a line is not redrawn just because the callback changed, so
/// passing a callback's value directly keeps calling the old one.
RunRendering tappableText(
  String text,
  TextStyle style, {
  required OnCustomTap onTap,
}) {
  final recognizer = TapGestureRecognizer()..onTap = () => onTap(text);
  return (
    span: TextSpan(
      text: text,
      style: style,
      recognizer: recognizer,
      semanticsLabel: text,
    ),
    dispose: recognizer.dispose,
  );
}
