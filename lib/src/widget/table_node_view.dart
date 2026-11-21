import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../render/natural_block_builders.dart';

class TableNodeView extends StatelessWidget {
  final TableNode node;

  final NaturalBlockScope scope;

  const TableNodeView({super.key, required this.node, required this.scope});

  List<Widget> _cells(TableRowNode row) {
    return List.generate(node.columns.length, (i) {
      final column = node.columns[i];
      final stated = i < row.children.length
          ? row.children[i]
          : TableCellNode();

      final cell = Padding(
        padding: scope.theme.tableCellPadding,
        child: scope.builders.tableCell(
          TableCellNode(
            children: stated.children,
            align: stated.align == HorizontalAlign.unstated
                ? column
                : stated.align,
          ),
          scope,
        ),
      );
      // An empty line sets its baseline apart from text's, so an empty cell
      // stays out of the row's baseline, as an empty cell of a row does.
      if (stated.children.isNotEmpty) return cell;
      return TableCell(
        verticalAlignment: TableCellVerticalAlignment.top,
        child: cell,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final stripe = scope.theme.tableStripe;

    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      border: scope.theme.tableBorder,
      children: List.generate(
        node.children.length,
        (i) => TableRow(
          decoration: stripe != null && i.isOdd
              ? BoxDecoration(color: stripe)
              : null,
          children: _cells(node.children[i]),
        ),
      ),
    );
  }
}
