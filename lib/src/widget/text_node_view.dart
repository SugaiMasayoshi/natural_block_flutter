import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../render/natural_block_builders.dart';
import '../render/run_handler.dart';
import 'natural_block_theme.dart';

class TextNodeView extends StatefulWidget {
  final TextNode node;

  final NaturalBlockScope scope;

  const TextNodeView({super.key, required this.node, required this.scope});

  @override
  State<TextNodeView> createState() => _TextNodeViewState();
}

/// Stateful only so the spans outlive a build.
///
/// Rebuilding replaces the recognizers the spans carry, and a recognizer that
/// has taken a pointer down owns an entry in the gesture arena: replace it
/// mid-gesture and the tap vanishes with no error anywhere. `build` runs for
/// reasons these spans owe nothing to -- an ancestor rebuilding, every frame
/// of an animating parent -- so they are kept until what they are made of
/// changes.
class _TextNodeViewState extends State<TextNodeView> {
  /// What the runs of this line left to release, which for a line of
  /// ordinary text is nothing at all.
  List<VoidCallback> _disposes = const [];

  /// What `build` hands over, so that a build which changes nothing does
  /// nothing.
  TextSpan _paragraph = const TextSpan();

  _SpanInputs? _builtFrom;

  @override
  void dispose() {
    _release();
    super.dispose();
  }

  /// Safe to call twice: the list is emptied, so the call from [dispose]
  /// finds nothing left after a rebuild already released it.
  void _release() {
    for (final dispose in _disposes) {
      dispose();
    }
    _disposes = const [];
    _paragraph = const TextSpan();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.scope.theme;

    // Everything the context decides is resolved here and handed down as
    // values, so that what a span is built from is also what it is
    // compared by. The root span and the size a `:+` counts from are one
    // expression, because two of them drift -- and then a `base` naming a
    // size makes `:+` render *smaller* than the text beside it.
    final rootStyle = DefaultTextStyle.of(context).style.merge(theme.base);

    // In `build` rather than the two change hooks: it runs after both, so
    // one question in one place answers for either.
    final from = (
      line: widget.node,
      theme: theme,
      rootStyle: rootStyle,
      customs: widget.scope.customs,
    );

    if (from != _builtFrom) {
      _builtFrom = from;
      _release();
      final drawn = _runSpans(from);
      _disposes = drawn.disposes;
      _paragraph = TextSpan(style: rootStyle, children: drawn.spans);
    }

    return Text.rich(_paragraph);
  }
}

/// Everything a line's spans are made of.
///
/// One value, because it is both what the spans are built from and what
/// decides whether the ones already built still hold. Two values could
/// disagree -- something could reach the building without reaching the
/// comparison, and then a change would never redraw.
typedef _SpanInputs = ({
  TextNode line,
  NaturalBlockTheme theme,
  TextStyle rootStyle,
  List<RunHandler> customs,
});

/// A line's runs as spans, and whatever any of them left to release.
///
/// A function of [from] alone rather than a method of the state, so it
/// cannot read anything the comparison does not see.
///
/// Only a run some handler claimed leaves anything to release. Which
/// `dispose` came from which span is never asked, which is why they are two
/// lists rather than one list of pairs.
({List<InlineSpan> spans, List<VoidCallback> disposes}) _runSpans(
  _SpanInputs from,
) {
  final theme = from.theme;
  final runs = from.line.children;

  // One span per run, so the length is known; every arm below fills its own
  // index and the switch is exhaustive, so no slot keeps the placeholder.
  final spans = List<InlineSpan>.filled(runs.length, const TextSpan());
  final disposes = <VoidCallback>[];

  for (var i = 0; i < runs.length; i++) {
    final run = runs[i];
    switch (run) {
      // A raw run is text the parser stopped reading, so the only thing to
      // do is not undo that: what the line is drawn in, made monospaced.
      case RawSpanNode():
        spans[i] = TextSpan(
          text: run.text,
          style: from.rootStyle.merge(theme.raw),
        );

      case TextSpanNode():
        final text = run.text;
        final baseSize = from.rootStyle.fontSize ?? theme.baseFontSize;
        final style = theme.styleFor(run.decoration, baseSize: baseSize);

        // Styled as actionable either way. What the handlers decide is how
        // it is drawn and whether it answers a tap: the first to answer
        // draws it, and the rest are not asked.
        RunRendering? claimed;
        if (run.decoration.isAction) {
          // `styleFor` leaves the size unstated where the source asked for
          // no step; a handler is handed the size the run actually draws at.
          final offered = style.copyWith(fontSize: style.fontSize ?? baseSize);
          for (final handler in from.customs) {
            claimed = handler(text, offered, theme);
            if (claimed != null) break;
          }
        }

        spans[i] = claimed?.span ?? TextSpan(text: text, style: style);
        if (claimed != null) disposes.add(claimed.dispose);
    }
  }

  return (spans: spans, disposes: disposes);
}
