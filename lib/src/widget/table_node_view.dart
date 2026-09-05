import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../registry/natural_block_registry.dart';
import 'block_align_layout.dart';

class TableNodeView extends StatelessWidget {
  final TableNode node;

  final NaturalBlockScope scope;

  const TableNodeView({super.key, required this.node, required this.scope});

  /// [row]'s cells, squared off to the table's width and with each cell's
  /// alignment resolved against its column.
  ///
  /// Both are this layer's business, not the parser's. `TableRow` requires
  /// every row to hold the same number of children, and a cell that stated
  /// no alignment of its own is drawn with whatever its column stated -- a
  /// question about how to draw, asked of a tree that only records what was
  /// written. Going back through the registry keeps a caller's own
  /// `ColumnNode` builder working inside a table.
  List<NaturalBlockNode> _squared(RowNode row) => [
    for (var i = 0; i < node.columns.length; i++)
      ColumnNode(
        children: i < row.children.length ? row.children[i].children : const [],
        align:
            (i < row.children.length ? row.children[i].align : null) ??
            node.columns[i],
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final stripe = scope.theme.tableStripe;

    final table = Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      border: scope.theme.tableBorder,
      children: [
        for (var i = 0; i < node.children.length; i++)
          TableRow(
            decoration: stripe != null && i.isOdd
                ? BoxDecoration(color: stripe)
                : null,
            children: [
              for (final cell in scope.buildAll(
                context,
                _squared(node.children[i]),
              ))
                Padding(padding: scope.theme.tableCellPadding, child: cell),
            ],
          ),
      ],
    );

    final sized = IntrinsicWidth(child: table);

    if (node.align.isStart) return sized;
    return Align(alignment: node.align.alignment, child: sized);
  }
}
