import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

class ColumnNodeView extends StatelessWidget {
  final List<Widget> children;

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
