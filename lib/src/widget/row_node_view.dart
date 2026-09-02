// 【解説】[17/21] 横並び。1つの RowNode を受け取り、セルごとに1列を作る。
// 【解説】
// 【解説】 なぜ等分(Expanded)なのかが最大の読みどころ。この widget は自分の行しか
// 【解説】 見えず、隣の行のセルの内容を知らない。だから「既知の幅を等分する」以外に、
// 【解説】 行をまたいで一貫する幅の決め方が存在しない。連続した行が表に見えるのは
// 【解説】 これによる。内容に応じた列幅はこの階層では原理的に作れない。
// 【解説】
// 【解説】 幅が無限だと Expanded は使えない(Rowがflexの子をレイアウトできない)ので、
// 【解説】 その場合だけ内容幅に退避する。ただしこれは等価な描画ではなく劣化で、
// 【解説】 列は揃わなくなり寄せも無効になる。描画されないよりまし、という判断。
// 【解説】 → 表を本格的にやるなら、ここではなく ColumnNodeView 側で連続した
// 【解説】   RowNode をまとめて Table にする必要がある(現時点では未実装)。
// 【解説】 次: lib/src/widget/table_node_view.dart（RowNodeView と対になる）

import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../registry/natural_block_registry.dart';
import 'natural_block_theme.dart';

/// Renders one [RowNode] as a horizontal [Row], one [Expanded] cell per
/// child [ColumnNode] -- so every cell of a row gets an equal share of the
/// available width.
///
/// Each cell is built through [registry] (via `buildAll`), the same way
/// [NaturalBlockRegistry.buildAll] builds any other list of nodes -- so a
/// builder registered for [ColumnNode], or for any node type nested inside
/// a cell, applies to row cells too instead of row rendering being a
/// special case that bypasses the registry.
///
/// ## Why equal shares, and why cells shrink-wrap in an unbounded width
///
/// Equal shares are not an arbitrary default: they are the only width
/// policy that stays consistent *across* rows here. A [RowNodeView] renders
/// one [RowNode] and cannot see its siblings, so nothing about a cell's
/// content is shared between rows. Splitting a known width into equal
/// fractions is what makes the columns of consecutive rows line up, which
/// is what makes a run of rows read as a table at all. Content-driven
/// column widths would require laying every row out together and so cannot
/// be done at this level.
///
/// That policy needs a width to divide, and [Expanded] cannot exist in a
/// [Row] whose own width is unbounded (inside a horizontally scrolling
/// parent, or nested in another [Row]) -- it throws. Rather than let an
/// alignment-free document stop rendering there, this falls back to
/// shrink-wrapped cells, the same way `ColumnNodeView` falls back to
/// [Align] instead of a width-filling `SizedBox`.
///
/// **The fallback is a degradation, not an equivalent rendering.** With no
/// width to divide, columns no longer line up across rows and the `=<`/
/// `=>`/`=^` alignment markers become no-ops (a cell exactly as wide as its
/// content has nothing to align within). A table rendered in an unbounded
/// width stops looking like a table. That is accepted here only because the
/// alternative is not rendering at all.
class RowNodeView extends StatelessWidget {
  /// The row to render; each entry of [RowNode.children] becomes one cell,
  /// in order -- [Expanded] where a width is available to divide, otherwise
  /// shrink-wrapped.
  final RowNode node;

  /// Styling passed through to each cell.
  final NaturalBlockTheme theme;

  /// Registry used to build each cell -- and, recursively, whatever that
  /// cell's own [ColumnNode] children contain.
  final NaturalBlockRegistry registry;

  /// What to do with actionable runs inside the cells -- see
  /// `NaturalBlockView.onActionTap` and `NaturalBlockView.onActionBuild`.
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
