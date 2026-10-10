import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import 'natural_block_builders.dart';

// A block holds text, raw regions and tables in any order, so what a child
// is only settles while reading. These switches are where that settles
// into a typed call; everything past them has the exact type. Where the
// tree already names one kind -- a row's cells, a table's rows -- the
// caller reaches for that builder directly.

/// A widget for each of [nodes]: the blocks and rows a document holds.
List<Widget> buildLayouts(List<LayoutNode> nodes, NaturalBlockScope scope) => [
  for (final node in nodes)
    switch (node) {
      RowNode() => scope.builders.row(node, scope),
      ColumnNode() => scope.builders.column(node, scope),
    },
];

/// A widget for each of [nodes]: the lines, raw blocks and tables a block or
/// a table cell holds.
List<Widget> buildContents(List<ContentNode> nodes, NaturalBlockScope scope) =>
    [
      for (final node in nodes)
        switch (node) {
          TableNode() => scope.builders.table(node, scope),
          TextNode() => scope.builders.text(node, scope),
          RawNode() => scope.builders.raw(node, scope),
        },
    ];
