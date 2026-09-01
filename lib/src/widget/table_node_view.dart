// 【解説】[14.5/16] 表。RowNodeView と対になる存在で、違いは幅の決め方にある。
// 【解説】
// 【解説】 RowNodeView は1行しか見えないので既知の幅を等分するしかない。
// 【解説】 TableNode は行をまとめて持っているので、ここでは全行を一度に
// 【解説】 レイアウトでき、列幅を中身に合わせられる。これが | ~ で表を
// 【解説】 宣言させた理由そのもの。
// 【解説】
// 【解説】 IntrinsicWidth で包んでいるのが要点。Table は素のままだと与えられた
// 【解説】 幅いっぱいに広がり、余りを各列に配ってしまうので、内容幅に収まらない。
// 【解説】 実測: フォント14の3列表で、包まないと列が 0/288/548、包むと 0/84/174。

import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../registry/natural_block_registry.dart';
import 'natural_block_theme.dart';

/// Renders one [TableNode] as a Flutter [Table] whose columns are as wide as
/// their content.
///
/// This is the counterpart to `RowNodeView`, and the difference between them
/// is the whole reason a table has to be declared. A `RowNodeView` renders
/// one row and cannot see its siblings, so equal fractions of a known width
/// are the only policy that keeps columns lined up between rows. A
/// [TableNode] holds every row together, so its columns can instead be sized
/// to their content -- and *because* they are, a table needs padding and
/// rules to stay readable, which is what [NaturalBlockTheme.tableCellPadding]
/// and [NaturalBlockTheme.tableBorder] supply.
///
/// Sizing to content also means the table no longer fills the width, which
/// is what makes [TableNode.align] meaningful: there is space around it to be
/// positioned within, unlike a plain row.
class TableNodeView extends StatelessWidget {
  /// The table to render. Every row is guaranteed by the parser to hold the
  /// same number of cells -- a row of a different width ends the table
  /// instead of joining it -- which is also what Flutter's [Table] requires.
  final TableNode node;

  /// Styling for the cells, and for the table's own padding, rules, and
  /// striping.
  final NaturalBlockTheme theme;

  /// Registry used to build each cell, so a builder registered for
  /// [ColumnNode] (or anything nested inside a cell) applies here too.
  final NaturalBlockRegistry registry;

  /// What to do with actionable runs inside the cells -- see
  /// `NaturalBlockView.onActionTap` and `NaturalBlockView.onActionBuild`.
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
      // The policy the whole feature exists for: each column as wide as its
      // widest cell, agreed across every row.
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

    // Table on its own expands to whatever width it is offered and hands the
    // slack to its columns, which would undo the content-sizing above.
    // IntrinsicWidth holds it to the width its columns actually need.
    final sized = IntrinsicWidth(child: table);

    // Same treatment as `ColumnNodeView`: a start-aligned table is left to
    // hug its content, and anything else is wrapped in an [Align] rather
    // than a width-filling box, so an alignment marker can never make a
    // document stop rendering where the available width is unbounded.
    if (node.align == BlockAlign.start) return sized;
    return Align(alignment: _alignmentFor(node.align), child: sized);
  }

  static AlignmentGeometry _alignmentFor(BlockAlign align) => switch (align) {
    BlockAlign.start => AlignmentDirectional.centerStart,
    BlockAlign.center => Alignment.center,
    BlockAlign.end => AlignmentDirectional.centerEnd,
  };
}
