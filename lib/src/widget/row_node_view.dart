import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../registry/natural_block_registry.dart';

class RowNodeView extends StatelessWidget {
  final RowNode node;

  final NaturalBlockScope scope;

  const RowNodeView({super.key, required this.node, required this.scope});

  @override
  Widget build(BuildContext context) {
    final cells = scope.buildAll(context, node.children);

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
