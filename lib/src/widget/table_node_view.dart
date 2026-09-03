import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../registry/natural_block_registry.dart';
import 'natural_block_theme.dart';

class TableNodeView extends StatelessWidget {
  final TableNode node;

  final NaturalBlockTheme theme;

  final NaturalBlockRegistry registry;

  final NaturalBlockActions actions;

  const TableNodeView({
    super.key,
    required this.node,
    required this.theme,
    required this.registry,
    this.actions = NaturalBlockActions.none,
  });

  @override
  Widget build(BuildContext context) {
    final stripe = theme.tableStripe;

    final table = Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      border: theme.tableBorder,
      children: [
        for (var i = 0; i < node.children.length; i++)
          TableRow(
            decoration: stripe != null && i.isOdd
                ? BoxDecoration(color: stripe)
                : null,
            children: [
              for (final cell in registry.buildAll(
                context,
                node.children[i].children,
                theme,
                actions,
              ))
                Padding(padding: theme.tableCellPadding, child: cell),
            ],
          ),
      ],
    );

    final sized = IntrinsicWidth(child: table);

    if (node.align == BlockAlign.start) return sized;
    return Align(alignment: _alignmentFor(node.align), child: sized);
  }

  static AlignmentGeometry _alignmentFor(BlockAlign align) => switch (align) {
    BlockAlign.start => AlignmentDirectional.centerStart,
    BlockAlign.center => Alignment.center,
    BlockAlign.end => AlignmentDirectional.centerEnd,
  };
}
