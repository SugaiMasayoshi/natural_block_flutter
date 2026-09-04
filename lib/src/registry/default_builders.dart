import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../widget/column_node_view.dart';
import '../widget/natural_block_theme.dart';
import '../widget/row_node_view.dart';
import '../widget/table_node_view.dart';
import '../widget/text_node_view.dart';
import '../widget/verbatim_node_view.dart';
import 'natural_block_registry.dart';

Widget buildRowNode(
  BuildContext context,
  NaturalBlockNode node,
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

Widget buildColumnNode(
  BuildContext context,
  NaturalBlockNode node,
  NaturalBlockTheme theme,
  NaturalBlockRegistry registry,
  NaturalBlockActions actions,
) {
  final column = node as ColumnNode;
  final children = registry.buildAll(context, column.children, theme, actions);
  return ColumnNodeView(align: column.align, children: children);
}

Widget buildTextNode(
  BuildContext context,
  NaturalBlockNode node,
  NaturalBlockTheme theme,
  NaturalBlockRegistry registry,
  NaturalBlockActions actions,
) {
  return TextNodeView(node: node as TextNode, theme: theme, actions: actions);
}

Widget buildTableNode(
  BuildContext context,
  NaturalBlockNode node,
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

Widget buildVerbatimNode(
  BuildContext context,
  NaturalBlockNode node,
  NaturalBlockTheme theme,
  NaturalBlockRegistry registry,
  NaturalBlockActions actions,
) {
  return VerbatimNodeView(node: node as VerbatimNode, theme: theme);
}
