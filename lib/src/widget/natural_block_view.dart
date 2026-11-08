import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'package:natural_block/natural_block.dart';

import '../custom/run_handler.dart';
import '../render/natural_block_builders.dart';
import '../render/natural_block_render.dart';
import 'column_node_view.dart';
import 'natural_block_theme.dart';

/// Draws natural_block markup: from a [NaturalBlockView.new] source, or from
/// a [NaturalBlockView.document] tree already parsed.
sealed class NaturalBlockView extends StatefulWidget {
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

  const NaturalBlockView._({
    super.key,
    required this.theme,
    required this.builders,
    required this.customs,
  });

  /// Parses [source] and draws it.
  const factory NaturalBlockView({
    Key? key,
    required String source,
    NaturalBlockTheme? theme,
    @mustBeConst NaturalBlockBuilders builders,
    @mustBeConst List<RunHandler> customs,
  }) = _SourceView;

  /// Draws [document] without parsing, for a tree that was parsed to be read
  /// first, or one built or cut apart by hand.
  const factory NaturalBlockView.document({
    Key? key,
    required DocumentNode document,
    NaturalBlockTheme? theme,
    @mustBeConst NaturalBlockBuilders builders,
    @mustBeConst List<RunHandler> customs,
  }) = _DocumentView;

  @override
  State<NaturalBlockView> createState() => _NaturalBlockViewState();
}

final class _SourceView extends NaturalBlockView {
  final String source;

  const _SourceView({
    super.key,
    required this.source,
    super.theme,
    super.builders = NaturalBlockBuilders.defaults,
    super.customs = const [],
  }) : super._();
}

final class _DocumentView extends NaturalBlockView {
  final DocumentNode document;

  const _DocumentView({
    super.key,
    required this.document,
    super.theme,
    super.builders = NaturalBlockBuilders.defaults,
    super.customs = const [],
  }) : super._();
}

class _NaturalBlockViewState extends State<NaturalBlockView> {
  DocumentNode _read() => switch (widget) {
    _SourceView(:final source) => NaturalBlockParser.parse(source),
    _DocumentView(:final document) => document,
  };

  late DocumentNode _document = _read();

  @override
  void didUpdateWidget(NaturalBlockView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final unchanged = switch ((widget, oldWidget)) {
      (_SourceView(:final source), _SourceView(source: final was)) =>
        source == was,
      (_DocumentView(:final document), _DocumentView(document: final was)) =>
        identical(document, was),
      _ => false,
    };
    if (!unchanged) _document = _read();
  }

  // The same widget object lets Flutter skip the whole subtree.
  Widget? _cached;
  DocumentNode? _drawnDocument;
  NaturalBlockScope? _drawnScope;

  // Hot reload changes code, not inputs, so nothing drawn is kept.
  @override
  void reassemble() {
    super.reassemble();
    _document = _read();
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
