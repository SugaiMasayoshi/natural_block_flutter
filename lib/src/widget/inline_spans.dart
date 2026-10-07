import 'package:flutter/widgets.dart';

import 'run_span.dart';

/// A line's runs as spans, kept until what they are made of changes.
///
/// Rebuilding replaces the recognizers the spans carry, and a recognizer that
/// has taken a pointer down owns an entry in the gesture arena: replace it
/// mid-gesture and the tap vanishes with no error anywhere. `build` runs for
/// reasons these spans owe nothing to -- an ancestor rebuilding, every frame
/// of an animating parent -- so the owner calls [update] on each of those and
/// this decides.
class InlineSpans {
  List<InlineSpan> spans = const [];

  SpanInputs? _from;

  /// Rebuilds the spans if [from] differs from what the current ones were
  /// built from, and does nothing if it does not.
  ///
  /// `onTap` is compared like the rest of [from], so hand over something
  /// stable -- a method of the owning state rather than a closure written at
  /// the call site. Dart never considers two closure literals equal, so a
  /// fresh one each time would rebuild every time, and every tap held across
  /// a rebuild would be lost.
  void update(BuildContext context, SpanInputs from) {
    if (from == _from) return;
    _from = from;

    dispose();
    spans = [for (final run in from.node.children) runSpan(context, run, from)];
  }

  /// Releases the recognizers the current spans carry.
  ///
  /// Every span here was made by `runSpan`, so every recognizer in one is
  /// this package's: there is nothing to tell apart, only something to
  /// release. A `WidgetRun`'s span carries none -- what answers a tap there
  /// is a widget, and Flutter owns it.
  ///
  /// Safe to call twice: the list is emptied, so a later call from the
  /// owner's own `dispose` finds nothing left to release.
  void dispose() {
    for (final span in spans) {
      if (span is TextSpan) span.recognizer?.dispose();
    }
    spans = const [];
  }
}
