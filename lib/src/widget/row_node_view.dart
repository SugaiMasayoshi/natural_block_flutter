import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import 'natural_block_theme.dart';
import 'text_node_view.dart';

/// Renders one or more consecutive [RowNode]s as a single horizontal [Row].
///
/// The parser represents "a=b" as two sibling [RowNode]s (each holding one
/// cell), not as one [RowNode] holding two cells -- so a Row's cells come
/// from a *group* of consecutive RowNode siblings, one cell per node.
///
/// **Non-`TextNode` cell content is dropped.** Each [RowNode]'s `children`
/// is `List<ContentNode>`, which the `natural_block` package defines as
/// sealed over both [TextNode] and `TextSpanNode`. This view renders only
/// the [TextNode] children (`whereType<TextNode>()`), so a bare
/// `TextSpanNode` cell produces no widget. The drop happens in both debug
/// and release builds; in debug it is announced via `debugPrint`, matching
/// how `NaturalBlockRegistry`'s fallback reports an unhandled node, while
/// release stays silent.
class RowNodeView extends StatelessWidget {
  /// The [RowNode] siblings whose cells make up this Row, one cell per
  /// node -- see the class doc for why this is a list rather than a
  /// single node.
  final List<RowNode> nodes;

  /// Styling passed through to each cell's [TextNodeView].
  final NaturalBlockTheme theme;

  const RowNodeView({super.key, required this.nodes, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      final dropped = nodes
          .expand((node) => node.children)
          .where((child) => child is! TextNode)
          .length;
      if (dropped > 0) {
        debugPrint(
          'RowNodeView: dropped $dropped non-TextNode cell(s) '
          '(e.g. a bare TextSpanNode) with no corresponding rendering.',
        );
      }
    }

    final children = nodes
        .expand((node) => node.children.whereType<TextNode>())
        .map(
          (textNode) => Expanded(
            child: TextNodeView(node: textNode, theme: theme),
          ),
        )
        .toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}
