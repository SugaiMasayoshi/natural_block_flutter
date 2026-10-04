import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../render/natural_block_actions.dart';
import '../render/natural_block_builders.dart';
import '../render/natural_block_render.dart';
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

  final NaturalBlockActions actions;

  const NaturalBlockView({
    super.key,
    required this.source,
    this.theme,
    this.builders = NaturalBlockBuilders.defaults,
    this.actions = NaturalBlockActions.none,
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

  /// Drops the drawn tree when an inherited widget changes.
  ///
  /// A builder of the caller's own is handed this context and may read one --
  /// a `MediaQuery`, their own theme -- and bake what it read into the
  /// widget. The tree cannot say what was read, so the only safe answer is
  /// to draw again.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cached = null;
  }

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
  _DrawnFrom? _drawnFrom;

  /// The actions handed to the tree: a stand-in that reads the current widget
  /// when it fires.
  ///
  /// This is what keeps `onTap` out of the comparison below. A caller writes
  /// it as a closure in their own `build`, and two closures are never equal in
  /// Dart, so comparing it would miss every single time. Reading it at tap
  /// time instead means a cached tree still calls the newest callback.
  ///
  /// Null is passed through, because whether a run is tappable at all -- and
  /// so whether it is announced to a screen reader -- depends on it.
  ///
  /// `buildSpan` is handed over as it came. It *makes* the span, and a span
  /// already made is kept, so a different one has to redraw -- which is why
  /// it is compared below. Wrapping it would give the lines a fresh identity
  /// on every rebuild, and every line would redraw its spans even when only
  /// one of them changed.
  NaturalBlockActions _liveActions() => NaturalBlockActions(
    onTap: widget.actions.onTap == null
        ? null
        : (text) => widget.actions.onTap!(text),
    buildSpan: widget.actions.buildSpan,
  );

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? NaturalBlockTheme.fromContext(context);

    final from = (
      document: _document,
      theme: theme,
      builders: widget.builders,
      buildSpan: widget.actions.buildSpan,
      tappable: widget.actions.onTap != null,
    );

    if (_cached == null || from != _drawnFrom) {
      _drawnFrom = from;
      final scope = NaturalBlockScope(
        theme: theme,
        builders: widget.builders,
        actions: _liveActions(),
      );
      _cached = ColumnNodeView(
        children: buildLayouts(context, _document.children, scope),
      );
    }

    return _cached!;
  }
}

/// What a drawn tree was drawn from, so the next `build` can tell whether it
/// still holds.
typedef _DrawnFrom = ({
  DocumentNode document,
  NaturalBlockTheme theme,
  NaturalBlockBuilders builders,
  ActionSpanBuilder? buildSpan,
  bool tappable,
});
