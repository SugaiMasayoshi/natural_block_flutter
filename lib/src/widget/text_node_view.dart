import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../render/natural_block_builders.dart';
import 'inline_spans.dart';

class TextNodeView extends StatefulWidget {
  final TextNode node;

  final NaturalBlockScope scope;

  const TextNodeView({super.key, required this.node, required this.scope});

  @override
  State<TextNodeView> createState() => _TextNodeViewState();
}

class _TextNodeViewState extends State<TextNodeView> {
  /// This line's spans, which own the recognizers and keep themselves until
  /// what they are made of changes. Stateful only to hold these: they have to
  /// outlive a build, or a tap held across one is lost.
  final InlineSpans _line = InlineSpans();

  @override
  void dispose() {
    _line.dispose();
    super.dispose();
  }

  /// A method rather than a closure, so it compares equal across builds: a
  /// caller writing a fresh `onTap` on every build keeps the spans -- and the
  /// recognizers -- as they are. Whether there is one at all still shows
  /// through, because that decides if a run is tappable.
  void _handleTap(String text) => widget.scope.actions.onTap?.call(text);

  @override
  Widget build(BuildContext context) {
    // What every run of this line starts from: the ambient style with the
    // theme's `base` merged over it. The root span and the size a `:+` counts
    // from are the same expression, because two of them drift -- and then a
    // theme whose `base` names a size makes `:+` render *smaller* than the
    // text beside it.
    final rootStyle = DefaultTextStyle.of(context).style
        .merge(widget.scope.theme.base);

    // Asked on every build rather than from `didUpdateWidget` and
    // `didChangeDependencies`: build runs after both, and `update` does
    // nothing when nothing it is given has changed.
    _line.update(context, (
      node: widget.node,
      theme: widget.scope.theme,
      rootStyle: rootStyle,
      buildSpan: widget.scope.actions.buildSpan,
      onTap: widget.scope.actions.onTap == null ? null : _handleTap,
    ));

    return Text.rich(TextSpan(style: rootStyle, children: _line.spans));
  }
}
