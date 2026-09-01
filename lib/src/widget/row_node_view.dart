import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../registry/natural_block_registry.dart';
import 'natural_block_theme.dart';

/// Renders one [RowNode] as a horizontal [Row], one [Expanded] cell per
/// child [ColumnNode].
///
/// Each cell is built through [registry] (via `buildAll`), the same way
/// [NaturalBlockRegistry.buildAll] builds any other list of nodes -- so a
/// builder registered for [ColumnNode], or for any node type nested inside
/// a cell, applies to row cells too instead of row rendering being a
/// special case that bypasses the registry.
class RowNodeView extends StatelessWidget {
  /// The row to render; each entry of [RowNode.children] becomes one
  /// [Expanded] cell, in order.
  final RowNode node;

  /// Styling passed through to each cell.
  final NaturalBlockTheme theme;

  /// Registry used to build each cell -- and, recursively, whatever that
  /// cell's own [ColumnNode] children contain.
  final NaturalBlockRegistry registry;

  /// Forwarded to each cell -- see `NaturalBlockView.onActionTap`.
  final OnActionTap? onActionTap;

  const RowNodeView({
    super.key,
    required this.node,
    required this.theme,
    required this.registry,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final cells = registry
        .buildAll(context, node.children, theme, onActionTap)
        .map((cell) => Expanded(child: cell))
        .toList();

    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: cells);
  }
}
