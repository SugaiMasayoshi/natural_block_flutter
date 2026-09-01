// 【解説】[16/16 の前半] 既定の描画関数3つ。registry と widget を繋ぐだけの薄い層。
// 【解説】 ここが薄いことに意味があり、各 View は registry を知らずに済んでいる。
// 【解説】 buildColumnNode だけが registry.buildAll を再帰的に呼ぶ = 木を降りる場所。

import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../widget/column_node_view.dart';
import '../widget/natural_block_theme.dart';
import '../widget/row_node_view.dart';
import '../widget/text_node_view.dart';
import 'natural_block_registry.dart';

/// Default builder for [RowNode]: renders it via [RowNodeView], one
/// [Expanded] cell per child [ColumnNode].
Widget buildRowNode(
  BuildContext context,
  BlockNode node,
  NaturalBlockTheme theme,
  NaturalBlockRegistry registry,
  OnActionTap? onActionTap,
) {
  return RowNodeView(
    node: node as RowNode,
    theme: theme,
    registry: registry,
    onActionTap: onActionTap,
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
  OnActionTap? onActionTap,
) {
  final column = node as ColumnNode;
  final children = registry.buildAll(
    context,
    column.children,
    theme,
    onActionTap,
  );
  return ColumnNodeView(align: column.align, children: children);
}

/// Default builder for [TextNode]: renders it via [TextNodeView].
Widget buildTextNode(
  BuildContext context,
  BlockNode node,
  NaturalBlockTheme theme,
  NaturalBlockRegistry registry,
  OnActionTap? onActionTap,
) {
  return TextNodeView(
    node: node as TextNode,
    theme: theme,
    onActionTap: onActionTap,
  );
}
