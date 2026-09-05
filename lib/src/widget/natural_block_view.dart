import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../registry/natural_block_registry.dart';
import 'column_node_view.dart';
import 'natural_block_theme.dart';

class NaturalBlockView extends StatefulWidget {
  final String source;

  final NaturalBlockTheme theme;

  final NaturalBlockRegistry registry;

  final OnActionTap? onActionTap;

  final ActionSpanBuilder? onActionBuild;

  const NaturalBlockView({
    super.key,
    required this.source,
    this.theme = const NaturalBlockTheme(),
    this.registry = NaturalBlockRegistry.defaults,
    this.onActionTap,
    this.onActionBuild,
  });

  @override
  State<NaturalBlockView> createState() => _NaturalBlockViewState();
}

class _NaturalBlockViewState extends State<NaturalBlockView> {
  /// The parsed `source`, kept across rebuilds.
  ///
  /// The tree is a pure function of `source` and owes nothing to the
  /// `BuildContext`, but `build` runs whenever an ancestor rebuilds -- a
  /// theme change, a `MediaQuery` change, every frame of an animating
  /// parent. Parsing there charged the whole document to each of those.
  late DocumentNode _document = NaturalBlockParser.parse(widget.source);

  @override
  void didUpdateWidget(NaturalBlockView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.source != oldWidget.source) {
      _document = NaturalBlockParser.parse(widget.source);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = NaturalBlockScope(
      theme: widget.theme,
      registry: widget.registry,
      actions: NaturalBlockActions(
        onTap: widget.onActionTap,
        buildSpan: widget.onActionBuild,
      ),
    );

    final children = scope.buildAll(context, _document.children);

    return ColumnNodeView(children: children);
  }
}
