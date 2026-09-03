import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../registry/natural_block_registry.dart';
import 'column_node_view.dart';
import 'natural_block_theme.dart';

class NaturalBlockView extends StatelessWidget {
  final String source;

  final NaturalBlockTheme theme;

  final NaturalBlockRegistry registry;

  final OnActionTap? onActionTap;

  final ActionSpanBuilder? onActionBuild;

  const NaturalBlockView({
    super.key,
    required this.source,
    this.theme = const NaturalBlockTheme(),
    this.registry = NaturalBlockRegistry.defaults,
    this.onActionTap,
    this.onActionBuild,
  });

  @override
  Widget build(BuildContext context) {
    final document = NaturalBlockParser.parse(source);
    final children = registry.buildAll(
      context,
      document.children,
      theme,
      NaturalBlockActions(onTap: onActionTap, buildSpan: onActionBuild),
    );

    return ColumnNodeView(children: children);
  }
}
