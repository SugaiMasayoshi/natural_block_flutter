import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

/// Renders pre-built child widgets in a vertically stacked [Column], honoring
/// `ColumnNode.align`.
///
/// Alignment is applied by moving the block itself -- setting the `Column`'s
/// [Column.crossAxisAlignment] -- rather than by giving the text a
/// `textAlign`. Both approaches produce identical results for lines of
/// differing length, since each line is its own child widget here, but block
/// alignment touches one widget instead of requiring this widget to stretch
/// *and* its text children to receive a `textAlign`. It also leaves a
/// [BlockAlign.start] block hugging its content as a real sized object,
/// which is room for per-block background/border decorations later.
///
/// A [BlockAlign.start] block is left to hug its content, as `Column`
/// normally does. A [BlockAlign.center] or [BlockAlign.end] block, however,
/// needs room on its cross axis before `crossAxisAlignment` has anything to
/// move it *within* -- a shrink-wrapped `Column` nested inside another
/// non-stretching `Column` (as this widget is, when it renders a block
/// nested in a bigger document) is offered only as much width as its
/// content needs, same as a start-aligned block. So a non-start block is
/// wrapped in an [Align], which takes the width its ancestors offer and
/// positions the block within it.
///
/// [Align] rather than a width-filling `SizedBox`: both position the block
/// identically when the width is bounded, but a `SizedBox` of infinite
/// width throws where the available width is itself unbounded -- inside a
/// horizontally scrolling parent, say. `Align` degrades to hugging the
/// content there instead of failing, so adding an alignment marker can
/// never make a document that rendered before stop rendering.
class ColumnNodeView extends StatelessWidget {
  /// The already-built widgets to stack vertically, in order. Building
  /// these from the source `ColumnNode`'s children (typically via
  /// `NaturalBlockRegistry.buildAll`) is the caller's responsibility --
  /// this widget only lays them out.
  final List<Widget> children;

  /// How to align [children] on the cross axis, taken from the source
  /// `ColumnNode.align`. Defaults to [BlockAlign.start].
  final BlockAlign align;

  const ColumnNodeView({
    super.key,
    required this.children,
    this.align = BlockAlign.start,
  });

  @override
  Widget build(BuildContext context) {
    final column = Column(
      crossAxisAlignment: _crossAxisAlignmentFor(align),
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
    // A start-aligned block keeps hugging its content; a centered or
    // end-aligned one needs room to be moved within -- see the class doc.
    if (align == BlockAlign.start) return column;
    return Align(alignment: _alignmentFor(align), child: column);
  }

  static CrossAxisAlignment _crossAxisAlignmentFor(BlockAlign align) {
    switch (align) {
      case BlockAlign.start:
        return CrossAxisAlignment.start;
      case BlockAlign.center:
        return CrossAxisAlignment.center;
      case BlockAlign.end:
        return CrossAxisAlignment.end;
    }
  }

  static AlignmentGeometry _alignmentFor(BlockAlign align) {
    switch (align) {
      case BlockAlign.start:
        return AlignmentDirectional.centerStart;
      case BlockAlign.center:
        return Alignment.center;
      case BlockAlign.end:
        return AlignmentDirectional.centerEnd;
    }
  }
}
