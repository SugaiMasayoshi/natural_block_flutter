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
  /// What `runSpan` answered for each run, and the spans the paragraph takes
  /// from it.
  ///
  /// Kept as it came so that releasing a line is asking each run to release
  /// what it made, rather than reading back a list of callbacks on its own.
  List<RunRendering> _runs = const [];
  List<InlineSpan> _spans = const [];

  /// What the current spans were built from, so a build can tell whether they
  /// still hold.
  SpanInputs? _builtFrom;

  @override
  void dispose() {
    _release();
    super.dispose();
  }

  /// Safe to call twice: the list is emptied, so the call from [dispose]
  /// finds nothing left to release after a rebuild already did.
  void _release() {
    for (final run in _runs) {
      run.dispose();
    }
    _runs = const [];
    _spans = const [];
  }

  /// A method rather than a closure, so it compares equal across builds: a
  /// caller writing a fresh `onTap` on every build keeps the spans -- and the
  /// recognizers -- as they are. Whether there is one at all still shows
  /// through, because that decides if a run is tappable.
  void _handleTap(String text) => widget.scope.onTap?.call(text);

  @override
  Widget build(BuildContext context) {
    // Everything the ambient style decides is resolved here, where the
    // `BuildContext` is, and handed over as values. Nothing further down
    // reads one: what a span is built from has to be what it is compared
    // by, or an ambient change reaches the drawing without reaching the
    // comparison and the line never redraws.
    final theme = widget.scope.theme;

    // The root span and the size a `:+` counts from are the same expression,
    // because two of them drift -- and then a theme whose `base` names a
    // size makes `:+` render *smaller* than the text beside it.
    final rootStyle = DefaultTextStyle.of(context).style.merge(theme.base);

    // Compared here rather than in `didUpdateWidget` and
    // `didChangeDependencies`: build runs after both, so one question in one
    // place answers for both -- and that is what closed the hole where an
    // ambient change the spans could not see replaced their recognizers.
    final from = (
      node: widget.node,
      theme: theme,
      rootStyle: rootStyle,
      customs: widget.scope.customs,
      onTap: widget.scope.onTap == null ? null : _handleTap,
    );

    if (from != _builtFrom) {
      _builtFrom = from;
      _release();
      _runs = [for (final run in widget.node.children) runSpan(run, from)];
      _spans = [for (final run in _runs) run.span];
    }

    return Text.rich(TextSpan(style: rootStyle, children: _spans));
  }
}
