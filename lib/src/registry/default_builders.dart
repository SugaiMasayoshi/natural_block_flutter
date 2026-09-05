import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../widget/column_node_view.dart';
import '../widget/row_node_view.dart';
import '../widget/table_node_view.dart';
import '../widget/text_node_view.dart';
import '../widget/verbatim_node_view.dart';
import 'natural_block_registry.dart';

Widget buildRowNode(
  BuildContext context,
  NaturalBlockNode node,
  NaturalBlockScope scope,
) => RowNodeView(node: node as RowNode, scope: scope);

Widget buildColumnNode(
  BuildContext context,
  NaturalBlockNode node,
  NaturalBlockScope scope,
) {
  final column = node as ColumnNode;
  return ColumnNodeView(
    align: column.align,
    children: scope.buildAll(context, column.children),
  );
}

Widget buildTextNode(
  BuildContext context,
  NaturalBlockNode node,
  NaturalBlockScope scope,
) => TextNodeView(node: node as TextNode, scope: scope);

Widget buildTableNode(
  BuildContext context,
  NaturalBlockNode node,
  NaturalBlockScope scope,
) => TableNodeView(node: node as TableNode, scope: scope);

Widget buildVerbatimNode(
  BuildContext context,
  NaturalBlockNode node,
  NaturalBlockScope scope,
) => VerbatimNodeView(node: node as VerbatimNode, theme: scope.theme);
