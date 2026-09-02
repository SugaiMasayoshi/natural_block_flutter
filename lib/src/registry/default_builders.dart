// 【解説】[20/21] 既定の描画関数3つ。registry と widget を繋ぐだけの薄い層。
// 【解説】 ここが薄いことに意味があり、各 View は registry を知らずに済んでいる。
// 【解説】 buildColumnNode だけが registry.buildAll を再帰的に呼ぶ = 木を降りる場所。
// 【解説】 次: lib/src/widget/natural_block_view.dart（最後の1枚）

import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../widget/column_node_view.dart';
import '../widget/natural_block_theme.dart';
import '../widget/row_node_view.dart';
import '../widget/table_node_view.dart';
import '../widget/text_node_view.dart';
import 'natural_block_registry.dart';

/// Default builder for [RowNode]: renders it via [RowNodeView], one
/// [Expanded] cell per child [ColumnNode].
Widget buildRowNode(
  BuildContext context,
  BlockNode node,
  NaturalBlockTheme theme,
  NaturalBlockRegistry registry,
  NaturalBlockActions actions,
) {
  return RowNodeView(
    node: node as RowNode,
    theme: theme,
    registry: registry,
    actions: actions,
  );
}

/// Default builder for [ColumnNode]: renders it via [ColumnNodeView], with
/// children recursively built through [registry] and `ColumnNode.align`
/// passed through so the block honors its alignment marker.
Widget buildColumnNode(
  BuildContext context,
  BlockNode node,
  NaturalBlockTheme theme,
  NaturalBlockRegistry registry,
  NaturalBlockActions actions,
) {
  final column = node as ColumnNode;
  final children = registry.buildAll(
    context,
    column.children,
    theme,
    actions,
  );
  return ColumnNodeView(align: column.align, children: children);
}

/// Default builder for [TextNode]: renders it via [TextNodeView].
Widget buildTextNode(
  BuildContext context,
  BlockNode node,
  NaturalBlockTheme theme,
  NaturalBlockRegistry registry,
  NaturalBlockActions actions,
) {
  return TextNodeView(
    node: node as TextNode,
    theme: theme,
    actions: actions,
  );
}

/// Default builder for [TableNode]: renders it via [TableNodeView], with
/// each row's cells recursively built through [registry].
Widget buildTableNode(
  BuildContext context,
  BlockNode node,
  NaturalBlockTheme theme,
  NaturalBlockRegistry registry,
  NaturalBlockActions actions,
) {
  return TableNodeView(
    node: node as TableNode,
    theme: theme,
    registry: registry,
    actions: actions,
  );
}
