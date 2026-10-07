import 'package:flutter/widgets.dart';

import '../widget/natural_block_theme.dart';

/// What tapping an actionable run means, decided by the app.
///
/// Nothing here interprets the text. The run's own text is the whole payload
/// -- a URL to open, a section to jump to, a mention to resolve -- and what
/// it means belongs to the app that showed the document.
typedef OnActionTap = void Function(String text);

/// How one actionable run is drawn, as answered by a [RunHandler].
///
/// Which case you return says who owns what the drawing needs released.
/// Getting that wrong is the one way a span can leak or a tap can vanish, so
/// it is a choice between named things rather than a convention to remember.
sealed class RunRendering {
  const RunRendering();
}

/// Drawn as text in the line.
///
/// The span is this package's to make, and so is the recognizer when [onTap]
/// is given -- which is what keeps a tap alive across a rebuild.
///
/// Leave [text] or [style] null to keep what the run would have been drawn
/// with. Setting [text] is how a payload becomes something to read: a
/// `user(alice)` run drawn as `alice`.
final class TextRun extends RunRendering {
  final String? text;

  final TextStyle? style;

  final VoidCallback? onTap;

  const TextRun({this.text, this.style, this.onTap});
}

/// Drawn as a widget sitting in the line.
///
/// Anything inside it is Flutter's to manage, a `GestureDetector` included,
/// so a widget run can answer a tap without anything here owning a
/// recognizer. It takes part in line breaking as one unbreakable box, and
/// its contents are outside the paragraph's text selection.
final class WidgetRun extends RunRendering {
  final Widget child;

  final PlaceholderAlignment alignment;

  const WidgetRun(this.child, {this.alignment = PlaceholderAlignment.middle});
}

/// Drawn as the span you made, used exactly as given.
///
/// The escape hatch, and the one case where this package releases nothing:
/// a recognizer your span carries is yours to dispose. Prefer [TextRun] when
/// text is what you want, since that leaves the owning here.
final class SpanRun extends RunRendering {
  final InlineSpan span;

  const SpanRun(this.span);
}

/// Answers how one actionable run is drawn, or null to leave it to the next
/// handler.
///
/// [text] is the run's own text, which is the payload. [style] is what the
/// run would have been drawn with, carrying a real size rather than an
/// unstated one. [onTap] is what the app wants done with this run, already
/// bound to its text, and null when the app wired nothing.
typedef RunHandler = RunRendering? Function(
  BuildContext context,
  String text,
  TextStyle style,
  NaturalBlockTheme theme,
  VoidCallback? onTap,
);

/// Draws an actionable run as tappable text, which is what a URL wants.
///
/// The default, and a handler like any other: leave it out of a view's
/// `customs` and actionable runs keep their style without answering a tap.
RunRendering? tappableText(
  BuildContext context,
  String text,
  TextStyle style,
  NaturalBlockTheme theme,
  VoidCallback? onTap,
) => onTap == null ? null : TextRun(onTap: onTap);
