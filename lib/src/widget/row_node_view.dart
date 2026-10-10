import 'package:flutter/widgets.dart';

/// A row's cells, each given an equal share of the width.
///
/// Takes widgets rather than a `RowNode`, because an equal share is all it
/// decides -- `buildRowNode` draws the cells and hands them over. A view here
/// takes a node only where it reads more of one than its children:
/// `TextNodeView` because a run becomes a span and never a widget,
/// `TableNodeView` because it squares rows off against the declared columns,
/// `RawNodeView` because it is a leaf.
class RowNodeView extends StatelessWidget {
  final List<Widget> cells;

  const RowNodeView({super.key, required this.cells});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final bounded = constraints.hasBoundedWidth;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
        children: List.generate(
          cells.length,
          (i) => bounded ? Expanded(child: cells[i]) : cells[i],
        ),
      );
    },
  );
}
