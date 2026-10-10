import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../widget/natural_block_theme.dart';

/// What tapping an actionable run means, decided by the app.
///
/// Nothing here interprets the text. The run's own text is the whole payload
/// -- a URL to open, a section to jump to, a mention to resolve -- and what
/// it means belongs to the app that showed the document.
typedef OnActionTap = void Function(String text);

/// How one actionable run is drawn: the span to put in the line, and what to
/// release when the line is rebuilt or goes away.
///
/// Anything the `span` carries is yours, a gesture recognizer included.
/// `dispose` is the only thing that releases it, and it is required rather than
/// omittable so that having nothing to release is written down -- `() {}` --
/// instead of being indistinguishable from having forgotten.
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

/// Answers how one actionable run is drawn, or null to leave it to the next
/// handler.
///
/// [text] is the run's own text, which is the payload. [style] is what the
/// run would have been drawn with, carrying a real size rather than an
/// unstated one. [onTap] is what the app wants done with this run, already
/// bound to its text, and null when the app wired nothing.
typedef RunHandler = RunRendering? Function(
  String text,
  TextStyle style,
  NaturalBlockTheme theme,
  VoidCallback? onTap,
);

/// Draws an actionable run as tappable text, which is what a URL wants.
///
/// The default, and a handler like any other: leave it out of a view's
/// `customs` and actionable runs keep their style without answering a tap.
/// It is also the shape to copy -- a recognizer made here, released by the
/// `dispose` handed back, and a `TextSpan` so the text still wraps.
///
/// Announced to a screen reader only because something answers it. Claiming
/// interactivity that nothing answers is a promise this package cannot keep,
/// which is why a run with no `onTap` is declined rather than underlined.
RunRendering? tappableText(
  String text,
  TextStyle style,
  NaturalBlockTheme theme,
  VoidCallback? onTap,
) {
  if (onTap == null) return null;

  final recognizer = TapGestureRecognizer()..onTap = onTap;
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
