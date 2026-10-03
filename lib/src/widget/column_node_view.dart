import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import 'horizontal_align_layout.dart';

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
    final column = Column(
      crossAxisAlignment: align.crossAxis,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
    if (align.isStart) return column;
    return Align(alignment: align.alignment, child: column);
  }
}
