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
  NaturalBlockNode node,
  NaturalBlockTheme theme,
  NaturalBlockRegistry registry,
) {
  return RowNodeView(node: node as RowNode, theme: theme, registry: registry);
}

/// Default builder for [ColumnNode]: renders it via [ColumnNodeView], with
/// children recursively built through [registry].
Widget buildColumnNode(
  BuildContext context,
  NaturalBlockNode node,
  NaturalBlockTheme theme,
  NaturalBlockRegistry registry,
) {
  final column = node as ColumnNode;
  final children = registry.buildAll(context, column.children, theme);
  return ColumnNodeView(children: children);
}

/// Default builder for [TextNode]: renders it via [TextNodeView].
Widget buildTextNode(
  BuildContext context,
  NaturalBlockNode node,
  NaturalBlockTheme theme,
  NaturalBlockRegistry registry,
) {
  return TextNodeView(node: node as TextNode, theme: theme);
}
