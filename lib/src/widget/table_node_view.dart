import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../render/natural_block_builders.dart';

class TableNodeView extends StatelessWidget {
  final TableNode node;

  final NaturalBlockScope scope;

  const TableNodeView({super.key, required this.node, required this.scope});

  /// [row]'s cells, one per declared column.
  ///
  /// Two things the tree deliberately leaves undone, both questions about
  /// drawing rather than about what was written: `TableRow` requires every
  /// row to hold the same number of children, and a cell that stated no
  /// alignment is drawn with whatever its column stated.
  List<TableCellNode> _squared(TableRowNode row) => [
    for (var i = 0; i < node.columns.length; i++)
      // A column this row never reached is a cell that stated nothing, which
      // [_resolved] already draws with the column's own alignment.
      _resolved(
        i < row.children.length ? row.children[i] : TableCellNode(),
        node.columns[i],
      ),
  ];

  /// [cell] drawn with its own alignment, or [column]'s where it stated none.
  ///
  /// `unstated` is a value rather than a gap, so this is a comparison rather
  /// than a `??`.
  static TableCellNode _resolved(TableCellNode cell, HorizontalAlign column) =>
      TableCellNode(
        children: cell.children,
        align: cell.align == HorizontalAlign.unstated ? column : cell.align,
      );

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
              for (final cell in _squared(node.children[i]))
                Padding(
                  padding: scope.theme.tableCellPadding,
                  child: scope.builders.tableCell(cell, scope),
                ),
            ],
          ),
      ],
    );

    // Positioned by the block that holds it, like anything else in a block.
    return IntrinsicWidth(child: table);
  }
}
