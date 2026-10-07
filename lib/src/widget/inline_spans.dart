import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../render/natural_block_actions.dart';
import '../render/natural_block_builders.dart';
import 'natural_block_theme.dart';
import 'run_span.dart';

/// What a set of spans was built from, so the next [InlineSpans.update] can
/// tell whether they still hold.
typedef _From = ({
  TextNode node,
  NaturalBlockTheme theme,
  TextStyle rootStyle,
  ActionSpanBuilder? buildSpan,
  void Function(String text)? onTap,
});

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
    spans = [
      for (final run in node.children)
        runSpan(context, run, scope, rootStyle, onTap: onTap),
    ];
  }

  /// Releases the recognizers the current spans carry.
  ///
  /// Safe to call twice: the list is emptied, so a later call from the
  /// owner's own `dispose` finds nothing left to release.
  void dispose() {
    for (final span in spans) {
      if (span is ActionSpan) span.dispose();
    }
    spans = const [];
  }
}
