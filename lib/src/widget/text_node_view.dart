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
  /// This line's spans, which own the recognizers and decide for themselves
  /// when they are stale. Everything this view does is tell them what they
  /// would be made of now.
  final InlineSpans _line = InlineSpans();

  /// What every run of this line starts from: the ambient style with the
  /// theme's `base` merged over it.
  ///
  /// The root span and the baseline a `:+` counts from must be this same
  /// expression. Two of them drift, and then a theme whose `base` names a
  /// size makes `:+` render *smaller* than the text beside it.
  TextStyle _rootStyle(BuildContext context) =>
      DefaultTextStyle.of(context).style.merge(widget.scope.theme.base);

  /// Both of the framework's "something may have changed" calls lead here.
  ///
  /// `didChangeDependencies` covers what is read through the context --
  /// `DefaultTextStyle` decides what every run starts from and can change
  /// without this widget's own fields changing at all. `didUpdateWidget`
  /// covers the fields. Neither knows whether the change reaches the spans,
  /// so both ask the same question in the same place.
  void _update() => _line.update(
    context,
    widget.node,
    widget.scope,
    _rootStyle(context),
    // A method of this state rather than a closure, so it compares equal
    // across rebuilds: a caller writing a fresh `onTap` on every build keeps
    // the spans -- and the recognizers -- as they are. Whether there is one
    // at all still shows through, because that decides if a run is tappable.
    onTap: widget.scope.actions.onTap == null ? null : _handleTap,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _update();
  }

  @override
  void didUpdateWidget(TextNodeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _update();
  }

  @override
  void dispose() {
    _line.dispose();
    super.dispose();
  }

  void _handleTap(String text) => widget.scope.actions.onTap?.call(text);

  @override
  Widget build(BuildContext context) =>
      Text.rich(TextSpan(style: _rootStyle(context), children: _line.spans));
}
