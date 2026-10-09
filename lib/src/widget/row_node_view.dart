import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../render/natural_block_builders.dart';

class RowNodeView extends StatelessWidget {
  final RowNode node;

  final NaturalBlockScope scope;

  const RowNodeView({super.key, required this.node, required this.scope});

  @override
  Widget build(BuildContext context) {
    // A row's cells are `ColumnNode`s and nothing else, so there is no kind
    // to choose: the column builder is called straight from the builders.
    final cells = [
      for (final cell in node.children) scope.builders.column(cell, scope),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.hasBoundedWidth;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            for (final cell in cells)
              if (bounded) Expanded(child: cell) else cell,
          ],
        );
      },
    );
  }
}
