import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../render/natural_block_builders.dart';
import '../render/natural_block_render.dart';
import '../render/run_handler.dart';
import 'column_node_view.dart';
import 'natural_block_theme.dart';

class NaturalBlockView extends StatefulWidget {
  final String source;

  /// Null takes the theme from the ambient one.
  final NaturalBlockTheme? theme;

  final NaturalBlockBuilders builders;

  /// The handlers a custom run is offered to, in order, until one claims it.
  /// With none, custom runs are styled and nothing more.
  ///
  /// Keep the list stable -- `const`, or held in your state. One written
  /// afresh each build redraws every line and loses a tap held across it.
  final List<RunHandler> customs;

  const NaturalBlockView({
    super.key,
    required this.source,
    this.theme,
    this.builders = NaturalBlockBuilders.defaults,
    this.customs = const [],
  });

  @override
  State<NaturalBlockView> createState() => _NaturalBlockViewState();
}

class _NaturalBlockViewState extends State<NaturalBlockView> {
  late DocumentNode _document = NaturalBlockParser.parse(widget.source);

  @override
  void didUpdateWidget(NaturalBlockView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.source != oldWidget.source) {
      _document = NaturalBlockParser.parse(widget.source);
    }
  }

  // The same widget object lets Flutter skip the whole subtree.
  Widget? _cached;
  DocumentNode? _drawnDocument;
  NaturalBlockScope? _drawnScope;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? NaturalBlockTheme.fromContext(context);

    final scope = NaturalBlockScope(
      theme: theme,
      builders: widget.builders,
      customs: widget.customs,
    );

    if (_cached == null ||
        _document != _drawnDocument ||
        scope != _drawnScope) {
      _drawnDocument = _document;
      _drawnScope = scope;
      _cached = ColumnNodeView(
        children: buildLayouts(_document.children, scope),
      );
    }

    return _cached!;
  }
}
