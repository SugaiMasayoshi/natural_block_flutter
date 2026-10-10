import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../widget/column_node_view.dart';
import '../widget/raw_node_view.dart';
import '../widget/row_node_view.dart';
import '../widget/table_node_view.dart';
import '../widget/text_node_view.dart';
import 'natural_block_builders.dart';
import 'natural_block_render.dart';

/// A row's cells are `ColumnNode`s and nothing else, so there is no kind to
/// choose: the column builder is called straight from the builders.
Widget buildRowNode(RowNode node, NaturalBlockScope scope) => RowNodeView(
  cells: List.generate(
    node.children.length,
    (i) => scope.builders.column(node.children[i], scope),
  ),
);

Widget buildColumnNode(ColumnNode node, NaturalBlockScope scope) =>
    ColumnNodeView(
      align: node.align,
      children: buildContents(node.children, scope),
    );

Widget buildTextNode(TextNode node, NaturalBlockScope scope) =>
    TextNodeView(node: node, scope: scope);

Widget buildTableNode(TableNode node, NaturalBlockScope scope) =>
    TableNodeView(node: node, scope: scope);

Widget buildRawNode(RawNode node, NaturalBlockScope scope) =>
    RawNodeView(node: node, theme: scope.theme);

/// A table's cell draws like a block: its contents stacked, aligned by what
/// the cell or its column stated.
Widget buildTableCellNode(TableCellNode node, NaturalBlockScope scope) =>
    ColumnNodeView(
      align: node.align,
      children: buildContents(node.children, scope),
    );
