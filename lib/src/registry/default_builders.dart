// 【解説】 読む順番 4/12: 種類ごとの既定の描き方。レジストリ(3)が差し替えの無い種類に使う。
// 【解説】 どれも NodeBuilder<その型> の形(context, node, scope)で、
// 【解説】 そのノード専用のウィジェット(5〜10)に渡すだけ。
// 【解説】 公開されているので、独自の描き方から「残りは既定に任せる」と書ける。
import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../widget/column_node_view.dart';
import '../widget/raw_node_view.dart';
import '../widget/row_node_view.dart';
import '../widget/table_node_view.dart';
import '../widget/text_node_view.dart';
import 'natural_block_registry.dart';

// 【解説】 => 式; は「本体が1つの式だけの関数」の短縮記法。
Widget buildRowNode(
  BuildContext context,
  RowNode node,
  NaturalBlockScope scope,
) => RowNodeView(node: node, scope: scope);

// 【解説】 列(ブロック): 中身を scope で1つずつウィジェットにしてから、縦に積むビューへ渡す。
Widget buildColumnNode(
  BuildContext context,
  ColumnNode node,
  NaturalBlockScope scope,
) => ColumnNodeView(
  align: node.align,
  children: scope.buildContents(context, node.children),
);

Widget buildTextNode(
  BuildContext context,
  TextNode node,
  NaturalBlockScope scope,
) => TextNodeView(node: node, scope: scope);

Widget buildTableNode(
  BuildContext context,
  TableNode node,
  NaturalBlockScope scope,
) => TableNodeView(node: node, scope: scope);

// 【解説】 raw ブロックは見た目の設定だけあれば描けるので、scope 全体ではなく theme を渡す。
Widget buildRawNode(
  BuildContext context,
  RawNode node,
  NaturalBlockScope scope,
) => RawNodeView(node: node, theme: scope.theme);

/// A table's cell draws like a block: its contents stacked, aligned by what
/// the cell or its column stated.
// 【解説】 寄せは表(10)が列から解決済みの値を入れて渡す。
Widget buildTableCellNode(
  BuildContext context,
  TableCellNode node,
  NaturalBlockScope scope,
) => ColumnNodeView(
  align: node.align,
  children: scope.buildContents(context, node.children),
);
