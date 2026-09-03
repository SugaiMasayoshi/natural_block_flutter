import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../registry/natural_block_registry.dart';
import 'natural_block_theme.dart';

class RowNodeView extends StatelessWidget {
  final RowNode node;

  final NaturalBlockTheme theme;

  final NaturalBlockRegistry registry;

  final NaturalBlockActions actions;

  const RowNodeView({
    super.key,
    required this.node,
    required this.theme,
    required this.registry,
    this.actions = NaturalBlockActions.none,
  });

  @override
  Widget build(BuildContext context) {
    final cells = registry.buildAll(context, node.children, theme, actions);

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
