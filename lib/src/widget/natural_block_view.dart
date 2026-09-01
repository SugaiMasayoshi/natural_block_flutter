import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../registry/natural_block_registry.dart';
import 'column_node_view.dart';
import 'natural_block_theme.dart';

/// Parses [source] as `natural_block` markup and renders it as Flutter
/// widgets.
///
/// Example:
/// ```dart
/// NaturalBlockView(
///   source: ':!Important Notice:!|Normal text',
/// )
/// ```
class NaturalBlockView extends StatelessWidget {
  /// The `natural_block` markup to parse and render, e.g.
  /// `':!Important Notice:!|Normal text'`. Parsed fresh on every build --
  /// see [NaturalBlockParser].
  final String source;

  /// Styling applied to the parsed nodes: semantic colors, emphasis, and
  /// font-size scaling. Defaults to `const NaturalBlockTheme()`; pass
  /// [NaturalBlockTheme.fromContext] to adapt to the ambient `Theme`, or a
  /// custom instance to override individual styles.
  final NaturalBlockTheme theme;

  /// Maps node types to the widgets that render them. Defaults to
  /// [NaturalBlockRegistry.defaults] (Row/Column/Text support); pass a
  /// registry built with [NaturalBlockRegistry.register] to add or
  /// override node rendering.
  final NaturalBlockRegistry registry;

  /// Called when an actionable span (`TextSpanNode.isAction == true`,
  /// written as `:@...:@` in markup) is tapped, with that span's own
  /// `text`. Left `null` (the default), actionable spans still render with
  /// `NaturalBlockTheme.action` but are not tappable. Neither the parser
  /// nor this package ever opens a URL or otherwise interprets `text` --
  /// deciding what it means is entirely this callback's responsibility.
  final OnActionTap? onActionTap;

  const NaturalBlockView({
    super.key,
    required this.source,
    this.theme = const NaturalBlockTheme(),
    this.registry = NaturalBlockRegistry.defaults,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final columnNode = NaturalBlockParser().parse(source);
    final children = registry.buildAll(
      context,
      columnNode.children,
      theme,
      onActionTap,
    );

    return ColumnNodeView(align: columnNode.align, children: children);
  }
}
