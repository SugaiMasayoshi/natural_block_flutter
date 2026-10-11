import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import 'natural_block_builders.dart';

/// A widget for each of [nodes]: the blocks and rows a document holds.
List<Widget> buildLayouts(List<LayoutNode> nodes, NaturalBlockScope scope) =>
    List.generate(nodes.length, (i) {
      final node = nodes[i];
      return switch (node) {
        RowNode() => scope.builders.row(node, scope),
        ColumnNode() => scope.builders.column(node, scope),
      };
    });

/// A widget for each of [nodes]: the lines, raw blocks and tables a block or
/// a table cell holds.
List<Widget> buildContents(List<ContentNode> nodes, NaturalBlockScope scope) =>
    List.generate(nodes.length, (i) {
      final node = nodes[i];
      return switch (node) {
        TableNode() => scope.builders.table(node, scope),
        TextNode() => scope.builders.text(node, scope),
        RawNode() => scope.builders.raw(node, scope),
      };
    });
