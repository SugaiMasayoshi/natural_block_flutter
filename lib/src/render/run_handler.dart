import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../widget/natural_block_theme.dart';

/// What tapping an custom run means, decided by the handler that drew it.
///
/// Nothing here interprets the text: no URL is opened. The run's own text
/// is the whole payload, and what it means belongs to the app.
typedef OnCustomTap = void Function(String text);

/// How one custom run is drawn: the span to put in the line, and what to
/// release when the line is rebuilt or goes away.
///
/// Anything the `span` carries is yours, a gesture recognizer included, and
/// `dispose` is the only thing that will ever release it. Required rather
/// than omittable, so that having nothing to release is written -- `() {}`
/// -- rather than indistinguishable from having forgotten.
typedef RunRendering = ({InlineSpan span, VoidCallback dispose});

/// A run drawn as [child] rather than as text, centred on the text beside it.
///
/// Not a wrapper around `WidgetSpan`: it answers the two questions one
/// leaves open.
///
/// [alignment] defaults to `middle`, not `WidgetSpan`'s own `bottom`, which
/// lines the text's bottom up with the box's and so leaves it hanging below
/// what it sits beside. `middle` costs no more line height and puts the two
/// centres together; the measurements are in the changelog.
///
/// And there is nothing to release, so this is the answer with no `dispose`
/// to get wrong: everything inside a `WidgetSpan` gets the ordinary widget
/// lifecycle, and Flutter disposes it. A `GestureDetector` in there answers
/// a tap the same way, with no recognizer for anyone to own.
///
/// [child] takes part in line breaking as one unbreakable box, so a long one
/// will not wrap. Return a `TextSpan` of your own for anything that should.
RunRendering widgetRun(
  Widget child, {
  PlaceholderAlignment alignment = PlaceholderAlignment.middle,
}) => (span: WidgetSpan(alignment: alignment, child: child), dispose: () {});

/// Answers how one custom run is drawn, or null to leave it to the next
/// handler.
///
/// [style] is what the run would have been drawn with, its `fontSize`
/// always resolved.
typedef RunHandler = RunRendering? Function(
  String text,
  TextStyle style,
  NaturalBlockTheme theme,
);

/// [text] drawn as tappable text, which is what a URL wants. Not a
/// [RunHandler] itself: [onTap] says what a tap means, so a handler of your
/// own supplies it --
///
/// ```dart
/// RunRendering? links(String text, TextStyle style, NaturalBlockTheme theme) =>
///     tappableText(text, style, onTap: openUrl);
/// ```
///
/// -- and keeps it stable (a top-level function, or a method of your state),
/// since a closure written afresh each build never compares equal to the
/// last and redraws every line.
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
