import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

class ColumnNodeView extends StatelessWidget {
  final List<Widget> children;

  final HorizontalAlign align;

  const ColumnNodeView({
    super.key,
    required this.children,
    this.align = HorizontalAlign.unstated,
  });

  @override
  Widget build(BuildContext context) {
    // A start-aligned block gets no `Align`, which breaks under unbounded width.
    final (:lines, :text, :block) = switch (align) {
      HorizontalAlign.unstated || HorizontalAlign.start => (
        lines: CrossAxisAlignment.start,
        text: TextAlign.start,
        block: null,
      ),
      HorizontalAlign.center => (
        lines: CrossAxisAlignment.center,
        text: TextAlign.center,
        block: Alignment.center,
      ),
      HorizontalAlign.end => (
        lines: CrossAxisAlignment.end,
        text: TextAlign.end,
        block: AlignmentDirectional.centerEnd,
      ),
    };

    final column = DefaultTextStyle.merge(
      textAlign: text,
      child: Column(
        crossAxisAlignment: lines,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
    return block == null ? column : Align(alignment: block, child: column);
  }
}
