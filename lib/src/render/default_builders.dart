import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../widget/column_node_view.dart';
import '../widget/raw_node_view.dart';
import '../widget/row_node_view.dart';
import '../widget/table_node_view.dart';
import '../widget/text_node_view.dart';
import 'natural_block_builders.dart';
import 'natural_block_render.dart';

Widget buildRowNode(
  BuildContext context,
  RowNode node,
  NaturalBlockScope scope,
) => RowNodeView(node: node, scope: scope);

Widget buildColumnNode(
  BuildContext context,
  ColumnNode node,
  NaturalBlockScope scope,
) => ColumnNodeView(
  align: node.align,
  children: buildContents(context, node.children, scope),
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

Widget buildRawNode(
  BuildContext context,
  RawNode node,
  NaturalBlockScope scope,
) => RawNodeView(node: node, theme: scope.theme);

/// A table's cell draws like a block: its contents stacked, aligned by what
/// the cell or its column stated.
Widget buildTableCellNode(
  BuildContext context,
  TableCellNode node,
  NaturalBlockScope scope,
) => ColumnNodeView(
  align: node.align,
  children: buildContents(context, node.children, scope),
);
