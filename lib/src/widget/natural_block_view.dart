import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../render/natural_block_builders.dart';
import '../render/natural_block_render.dart';
import '../render/run_handler.dart';
import 'column_node_view.dart';
import 'natural_block_theme.dart';

class NaturalBlockView extends StatefulWidget {
  final String source;

  /// How this document looks, or null to take it from the ambient theme.
  ///
  /// Null rather than a constant default: no constant is right in both a
  /// light and a dark theme, so the default is derived from the surrounding
  /// `ColorScheme` instead of guessed.
  final NaturalBlockTheme? theme;

  final NaturalBlockBuilders builders;

  /// The handlers an actionable run is offered to, in order, until one claims
  /// it.
  ///
  /// Drawing an actionable run as tappable text is itself a handler, so a
  /// list that leaves [tappableText] out draws those runs styled but inert.
  /// Images are handlers too, one per kind of source, so an app includes the
  /// ones it means: `const [NaturalBlockImages.network, tappableText]`.
  ///
  /// Keep the list stable -- `const`, or held in your state. One written out
  /// afresh on every build never compares equal to the last, which redraws
  /// every line and loses a tap held across the redraw.
  final List<RunHandler> customs;

  /// What tapping an actionable run means. Null leaves them inert.
  final OnActionTap? onTap;

  const NaturalBlockView({
    super.key,
    required this.source,
    this.theme,
    this.builders = NaturalBlockBuilders.defaults,
    this.customs = const [tappableText],
    this.onTap,
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

  /// The tree last drawn, and what it was drawn from.
  ///
  /// Returning the very same widget object is what lets Flutter skip the
  /// whole subtree: `updateChild` stops at a child whose widget has not
  /// changed. `build` runs for reasons the tree owes nothing to -- an
  /// ancestor rebuilding, every frame of an animating parent -- and without
  /// this each of those redrew the document.
  Widget? _cached;
  DocumentNode? _drawnDocument;
  NaturalBlockScope? _drawnScope;

  /// What the tree is handed in place of the caller's `onTap`: a method of
  /// this state, which compares equal across builds.
  ///
  /// A caller writes `onTap` as a closure in their own `build`, and two
  /// closures are never equal in Dart, so comparing it would miss every
  /// time. Reading it at tap time instead means a kept tree still calls the
  /// newest callback. Whether there is one at all does reach the comparison,
  /// because that decides if a run is tappable.
  void _handleTap(String text) => widget.onTap?.call(text);

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? NaturalBlockTheme.fromContext(context);

    final scope = NaturalBlockScope(
      theme: theme,
      builders: widget.builders,
      customs: widget.customs,
      onTap: widget.onTap == null ? null : _handleTap,
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
