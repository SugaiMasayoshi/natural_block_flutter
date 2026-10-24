import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:natural_block/natural_block.dart';

import '../custom/run_handler.dart';
import '../render/natural_block_builders.dart';
import '../render/natural_block_render.dart';
import 'column_node_view.dart';
import 'natural_block_theme.dart';

class NaturalBlockView extends StatefulWidget {
  final String source;

  /// Null takes the theme from the ambient one.
  final NaturalBlockTheme? theme;

  /// Must be `const`: a builder that reads your state would draw it once and
  /// keep it.
  final NaturalBlockBuilders builders;

  /// The handlers a custom run is offered to, in order, until one claims it.
  /// With none, custom runs are styled and nothing more.
  ///
  /// Must be `const`: the drawn lines are kept while this is the same list, so
  /// one written afresh each build redraws every line, and a handler that
  /// reads your state would draw it once and keep it. A tap gets the current
  /// `BuildContext` through `tappableText`'s `onTap` instead.
  final List<RunHandler> customs;

  const NaturalBlockView({
    super.key,
    required this.source,
    this.theme,
    @mustBeConst this.builders = NaturalBlockBuilders.defaults,
    @mustBeConst this.customs = const [],
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

  // Hot reload changes code, not inputs, so nothing drawn is kept.
  @override
  void reassemble() {
    super.reassemble();
    _document = NaturalBlockParser.parse(widget.source);
    _cached = null;
  }

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
