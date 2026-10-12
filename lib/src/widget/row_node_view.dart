import 'package:flutter/widgets.dart';

/// A row's cells, each given an equal share of the width.
///
/// Not usable inside `IntrinsicWidth` or `IntrinsicHeight`: it reads its
/// constraints with a `LayoutBuilder`, which cannot answer intrinsic sizes.
class RowNodeView extends StatelessWidget {
  final List<Widget> cells;

  const RowNodeView({super.key, required this.cells});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final bounded = constraints.hasBoundedWidth;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          cells.length,
          (i) => bounded ? Expanded(child: cells[i]) : cells[i],
        ),
      );
    },
  );
}
