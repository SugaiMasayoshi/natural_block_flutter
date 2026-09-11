import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../registry/natural_block_registry.dart';

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
  /// `TableCellNode` builder working inside a table.
  List<NaturalBlockNode> _squared(TableRowNode row) => [
    for (var i = 0; i < node.columns.length; i++)
      TableCellNode(
        children: i < row.children.length ? row.children[i].children : const [],
        align: _effectiveAlign(row, i),
      ),
  ];

  /// What the cell at [i] is drawn with: what it stated, else what its
  /// column declared.
  ///
  /// The resolution the tree deliberately does not do. `unstated` is a
  /// value rather than a gap, so this is a comparison rather than a `??`.
  HorizontalAlign _effectiveAlign(TableRowNode row, int i) {
    if (i >= row.children.length) return node.columns[i];
    final stated = row.children[i].align;
    return stated == HorizontalAlign.unstated ? node.columns[i] : stated;
  }

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

    // Positioned by the block that holds it, like anything else in a block.
    return IntrinsicWidth(child: table);
  }
}
