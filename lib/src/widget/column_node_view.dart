import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import 'spacer_node_view.dart';

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

    final content = children.any((child) => child is SpacerNodeView)
        ? LayoutBuilder(
            builder: (context, constraints) => SpacerRoom(
              isBounded: constraints.hasBoundedHeight,
              child: column,
            ),
          )
        : column;
    return block == null
        ? content
        : Align(alignment: block, heightFactor: 1, child: content);
  }
}
