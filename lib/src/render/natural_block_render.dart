import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import 'natural_block_builders.dart';

/// Choosing the builder for a node, for the places where the tree says only
/// that one of several kinds is there.
///
/// A block holds text, raw regions and tables in any order, so what a child
/// is only settles while reading. The switches here are where that settles
/// into a typed call; everything past them -- the fields, the builders, the
/// views -- has the exact type. Where the tree already names one kind (a
/// row's cells, a table's rows), there is nothing to choose and the caller
/// reaches for that field directly.

/// A widget for each of [nodes]: the blocks and rows a document holds.
List<Widget> buildLayouts(
  BuildContext context,
  List<LayoutNode> nodes,
  NaturalBlockScope scope,
) => [
  for (final node in nodes)
    switch (node) {
      RowNode() => scope.builders.row(context, node, scope),
      ColumnNode() => scope.builders.column(context, node, scope),
    },
];

/// A widget for each of [nodes]: the lines, raw blocks and tables a block or
/// a table cell holds.
List<Widget> buildContents(
  BuildContext context,
  List<ContentNode> nodes,
  NaturalBlockScope scope,
) => [
  for (final node in nodes)
    switch (node) {
      TableNode() => scope.builders.table(context, node, scope),
      TextNode() => scope.builders.text(context, node, scope),
      RawNode() => scope.builders.raw(context, node, scope),
    },
];
