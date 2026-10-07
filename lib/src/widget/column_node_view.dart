import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

class ColumnNodeView extends StatelessWidget {
  final List<Widget> children;

  /// The alignment the source stated, or `unstated` when it stated none.
  ///
  /// `unstated` and `start` both draw at the start today. They are kept apart
  /// so a theme can give unaligned blocks a look of its own without also
  /// overriding a block that asked for the start.
  final HorizontalAlign align;

  const ColumnNodeView({
    super.key,
    required this.children,
    this.align = HorizontalAlign.unstated,
  });

  @override
  Widget build(BuildContext context) {
    // Alignment reaches the drawing twice: `lines` sets where each line sits
    // inside the block, `block` where the block sits in the space it was
    // given. A block drawn at the start needs no `block` at all, and leaving
    // it off is what keeps an alignment marker from making a document stop
    // rendering where the available width is unbounded.
    final (:lines, :block) = switch (align) {
      HorizontalAlign.unstated || HorizontalAlign.start => (
        lines: CrossAxisAlignment.start,
        block: null,
      ),
      HorizontalAlign.center => (
        lines: CrossAxisAlignment.center,
        block: Alignment.center,
      ),
      HorizontalAlign.end => (
        lines: CrossAxisAlignment.end,
        block: AlignmentDirectional.centerEnd,
      ),
    };

    final column = Column(
      crossAxisAlignment: lines,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
    return block == null ? column : Align(alignment: block, child: column);
  }
}
