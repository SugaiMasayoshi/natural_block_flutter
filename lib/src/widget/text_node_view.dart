import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../render/natural_block_builders.dart';
import '../render/run_handler.dart';
import 'run_span.dart';

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
  /// What `runSpans` answered, kept as it came so that releasing a line is
  /// asking each run to release what it made.
  List<RunRendering> _runs = const [];

  /// What `build` hands over, so that a build which changes nothing does
  /// nothing.
  TextSpan _paragraph = const TextSpan();

  SpanInputs? _builtFrom;

  @override
  void dispose() {
    _release();
    super.dispose();
  }

  /// Safe to call twice: the list is emptied, so the call from [dispose]
  /// finds nothing left after a rebuild already released it.
  void _release() {
    for (final run in _runs) {
      run.dispose();
    }
    _runs = const [];
    _paragraph = const TextSpan();
  }

  /// A method, not a closure, so a caller writing a fresh `onTap` each
  /// build keeps the spans and their recognizers as they are.
  void _handleTap(String text) => widget.scope.onTap?.call(text);

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
      onTap: widget.scope.onTap == null ? null : _handleTap,
    );

    if (from != _builtFrom) {
      _builtFrom = from;
      _release();
      _runs = runSpans(from);
      _paragraph = TextSpan(
        style: rootStyle,
        children: [for (final run in _runs) run.span],
      );
    }

    return Text.rich(_paragraph);
  }
}
