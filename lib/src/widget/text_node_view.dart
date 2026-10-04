import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../render/natural_block_builders.dart';
import 'inline_node_span.dart';
import 'natural_block_theme.dart';

class TextNodeView extends StatefulWidget {
  final TextNode node;

  final NaturalBlockScope scope;

  const TextNodeView({super.key, required this.node, required this.scope});

  @override
  State<TextNodeView> createState() => _TextNodeViewState();
}

class _TextNodeViewState extends State<TextNodeView> {
  NaturalBlockTheme get _theme => widget.scope.theme;

  /// What every run of this line starts from: the ambient style with the
  /// theme's `base` merged over it.
  ///
  /// The root span and the baseline a `:+` counts from must be this same
  /// expression. Two of them drift, and then a theme whose `base` names a
  /// size makes `:+` render *smaller* than the text beside it.
  TextStyle _rootStyle(BuildContext context) =>
      DefaultTextStyle.of(context).style.merge(_theme.base);

  /// This line's runs as spans, built once and kept until something they are
  /// made of changes.
  ///
  /// Not built in `build`, because `build` runs for reasons the spans owe
  /// nothing to -- an ancestor rebuilding, every frame of an animating
  /// parent. Rebuilding them there replaced the recognizers below on each of
  /// those, and a recognizer that has taken a pointer down owns an entry in
  /// the gesture arena: replace it mid-gesture and the tap vanishes silently.
  /// Keeping the spans is what keeps the recognizers.
  late List<InlineSpan> _spans;

  /// The recognizers the spans above carry, owned so they can be disposed.
  List<TapGestureRecognizer> _recognizers = [];

  /// Rebuilds the spans when an inherited widget they read changes.
  ///
  /// `DefaultTextStyle` is one: it decides what every run starts from, and it
  /// can change without this widget's own fields changing at all.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _buildSpans();
  }

  /// Rebuilds the spans when what they are made of changes.
  ///
  /// `onTap`'s identity is deliberately not compared -- only whether it is
  /// null, which is what decides if a run carries a recognizer at all. The
  /// callback itself is read at tap time, so a caller writing a fresh closure
  /// on every build does not cost a rebuild here.
  @override
  void didUpdateWidget(TextNodeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget.scope;
    if (widget.node != oldWidget.node ||
        _theme != old.theme ||
        widget.scope.actions.buildSpan != old.actions.buildSpan ||
        (widget.scope.actions.onTap == null) != (old.actions.onTap == null)) {
      _buildSpans();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers = [];
  }

  /// Builds the spans, releasing the recognizers the previous ones carried.
  void _buildSpans() {
    _disposeRecognizers();
    final built = buildInlineSpans(
      context,
      widget.node,
      widget.scope,
      _rootStyle(context),
      // Read at tap time rather than captured, so a caller writing a fresh
      // closure on every build keeps the spans -- and the recognizers -- as
      // they are. Whether there is one at all is settled here, because that
      // decides if a run is tappable.
      onTap: widget.scope.actions.onTap == null ? null : _handleTap,
    );
    _spans = built.spans;
    _recognizers = built.recognizers;
  }

  void _handleTap(String text) => widget.scope.actions.onTap?.call(text);

  @override
  Widget build(BuildContext context) =>
      Text.rich(TextSpan(style: _rootStyle(context), children: _spans));
}
