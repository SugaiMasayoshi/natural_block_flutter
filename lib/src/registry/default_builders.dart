import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../widget/column_node_view.dart';
import '../widget/natural_block_theme.dart';
import '../widget/row_node_view.dart';
import '../widget/text_node_view.dart';
import 'natural_block_registry.dart';

/// Default builder for [RowNode]: consumes every consecutive [RowNode]
/// sibling starting at [index] and renders them together as one [Row] via
/// [RowNodeView], since the parser emits one RowNode per cell rather than
/// one RowNode holding every cell.
NodeBuildResult buildRowNode(
  BuildContext context,
  List<NaturalBlockNode> siblings,
  int index,
  NaturalBlockTheme theme,
  NaturalBlockRegistry registry,
) {
  // Seeding the list with a cast of the node at [index] does two things at
  // once: it fails loudly (like the sibling builders' casts) if this builder
  // was registered for a type it cannot handle, and it makes an empty result --
  // which would report `consumedCount: 0` and hang `buildAll`'s loop --
  // structurally impossible.
  final nodes = <RowNode>[siblings[index] as RowNode];
  for (var i = index + 1; i < siblings.length && siblings[i] is RowNode; i++) {
    nodes.add(siblings[i] as RowNode);
  }
  return NodeBuildResult(
    widget: RowNodeView(nodes: nodes, theme: theme),
    consumedCount: nodes.length,
  );
}

/// Default builder for [ColumnNode]: renders it via [ColumnNodeView], with
/// children recursively built through [registry].
NodeBuildResult buildColumnNode(
  BuildContext context,
  List<NaturalBlockNode> siblings,
  int index,
  NaturalBlockTheme theme,
  NaturalBlockRegistry registry,
) {
  final node = siblings[index] as ColumnNode;
  final children = registry.buildAll(context, node.children, theme);
  return NodeBuildResult(widget: ColumnNodeView(children: children));
}

/// Default builder for [TextNode]: renders it via [TextNodeView].
NodeBuildResult buildTextNode(
  BuildContext context,
  List<NaturalBlockNode> siblings,
  int index,
  NaturalBlockTheme theme,
  NaturalBlockRegistry registry,
) {
  final node = siblings[index] as TextNode;
  return NodeBuildResult(widget: TextNodeView(node: node, theme: theme));
}
