// 【解説】 読む順番 10/12: 表(~ で囲んだ部分)を Flutter の Table で描くウィジェット。
// 【解説】 パーサの木は「書かれたセル」だけを持つので、描く側でここの2つを行う:
// 【解説】   1. 短い行を表の幅まで空のセルで埋める(Table はすべての行のセル数が同じ必要がある)
// 【解説】   2. 寄せを書いていないセルに、列(1行目)の寄せを当てる
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
  // 【解説】 表の列数(node.columns.length)だけ、新しい TableCellNode を作り直して並べる。
  List<NaturalBlockNode> _squared(TableRowNode row) => [
    for (var i = 0; i < node.columns.length; i++)
      TableCellNode(
        // 【解説】 この行にその列のセルがあれば中身を使い、無ければ空(const [])で埋める。
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
    // 【解説】 埋めた空のセルは自分の寄せを持たないので、列の寄せを使う。
    if (i >= row.children.length) return node.columns[i];
    final stated = row.children[i].align;
    // 【解説】 セルが書いていなければ列の寄せ、書いていればセルの寄せ。
    return stated == HorizontalAlign.unstated ? node.columns[i] : stated;
  }

  @override
  Widget build(BuildContext context) {
    // 【解説】 縞模様の色。テーマで指定が無ければ null(縞なし)。
    final stripe = scope.theme.tableStripe;

    final table = Table(
      // 【解説】 各列の幅を、その列で一番広いセルの幅に合わせる(計算は重めだが表らしくなる)。
      defaultColumnWidth: const IntrinsicColumnWidth(),
      border: scope.theme.tableBorder,
      children: [
        for (var i = 0; i < node.children.length; i++)
          TableRow(
            // 【解説】 i.isOdd は「i が奇数か」。縞の色があるときだけ、奇数行に背景を付ける。
            decoration: stripe != null && i.isOdd
                ? BoxDecoration(color: stripe)
                : null,
            children: [
              // 【解説】 埋めた行を対応表経由でウィジェットにし、それぞれ余白で包む。
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
    // 【解説】 IntrinsicWidth: 表を中身の幅に縮める。これが無いと親の幅いっぱいに広がり、
    // 【解説】 それを入れたブロックの寄せ(中央・右)が効かなくなる。
    return IntrinsicWidth(child: table);
  }
}
