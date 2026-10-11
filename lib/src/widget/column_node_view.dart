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
    // Alignment reaches the drawing three times: `lines` sets where each line
    // sits inside the block, `text` where a wrapped paragraph's own lines sit
    // inside it, `block` where the block sits in the space it was given. A
    // block drawn at the start needs no `block` at all, and leaving it off is
    // what keeps an alignment marker from making a document stop rendering
    // where the available width is unbounded.
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
