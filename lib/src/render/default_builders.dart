import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../widget/column_node_view.dart';
import '../widget/raw_node_view.dart';
import '../widget/row_node_view.dart';
import '../widget/spacer_node_view.dart';
import '../widget/table_node_view.dart';
import '../widget/text_node_view.dart';
import 'natural_block_builders.dart';
import 'natural_block_render.dart';

Widget buildRowNode(RowNode node, NaturalBlockScope scope) => RowNodeView(
  cells: List.generate(
    node.children.length,
    (i) => scope.builders.cell(node.children[i], scope),
  ),
);

Widget buildCellNode(CellNode node, NaturalBlockScope scope) => ColumnNodeView(
  children: node.children.isEmpty
      ? [_emptyLine(scope)]
      : buildLayouts(node.children, scope),
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

Widget buildSpacerNode(SpacerNode node, NaturalBlockScope scope) =>
    SpacerNodeView(flex: node.flex);

Widget buildTableCellNode(TableCellNode node, NaturalBlockScope scope) =>
    ColumnNodeView(
      align: node.align,
      children: node.children.isEmpty
          ? [_emptyLine(scope)]
          : buildContents(node.children, scope),
    );

// An empty cell keeps a line's height, so a row of empty cells still shows.
Widget _emptyLine(NaturalBlockScope scope) => Text('', style: scope.theme.base);
