// 【解説】 読む順番 3/12: 「どのノードを、どのウィジェットで描くか」を決める仕組み。
// 【解説】 NaturalBlockRegistry がノードの種類ごとの差し替え口、
// 【解説】 NaturalBlockScope がそれと見た目・押したときの処理をまとめて木の下へ運ぶ箱。
// 【解説】 ノードの型は sealed(外部で増やせない)ので、差し替え口も種類ごとに固定で持つ。
import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../widget/natural_block_theme.dart';
import 'default_builders.dart';

// 【解説】 typedef: 関数の型に名前を付ける。<T> はノードの型で、種類ごとに狭められる。
typedef NodeBuilder<T extends NaturalBlockNode> = Widget Function(
  BuildContext context,
  T node,
  NaturalBlockScope scope,
);

// 【解説】 :@ の文字が押されたときに呼ばれる関数の型。押された run の文字列を受け取る。
typedef OnActionTap = void Function(String text);

// 【解説】 :@ の文字を独自に描く関数の型。InlineSpan? なので null を返すと「差し替えない」。
typedef ActionSpanBuilder = InlineSpan? Function(
  BuildContext context,
  String text,
  TextStyle style,
  NaturalBlockTheme theme,
);

// 【解説】 :@ に関する2つの差し替え口をまとめた値。
class NaturalBlockActions {
  final OnActionTap? onTap;

  final ActionSpanBuilder? buildSpan;

  const NaturalBlockActions({this.onTap, this.buildSpan});

  // 【解説】 static const: クラスに1つだけある定数。「何もしない」設定。
  static const NaturalBlockActions none = NaturalBlockActions();
}

/// Everything a node needs to draw itself that is not the node.
///
/// The three travel together the whole way down -- a table hands them to its
/// rows, a row to its cells, a cell to its lines -- and no level chooses a
/// different one of them for its children. Carried as one value they are
/// declared once instead of at every level, and adding a fourth thing later
/// does not rewrite every signature in between.
///
/// The `BuildContext` is deliberately *not* in here. It is the one thing that
/// does differ per level, and keeping it out is what lets the default
/// registry stay `const`.
class NaturalBlockScope {
  final NaturalBlockTheme theme;

  final NaturalBlockRegistry registry;

  final NaturalBlockActions actions;

  const NaturalBlockScope({
    this.theme = const NaturalBlockTheme(),
    this.registry = NaturalBlockRegistry.defaults,
    this.actions = NaturalBlockActions.none,
  });

  /// Builds a widget for each of [nodes]: the blocks and rows a document
  /// holds, or the cells a row holds.
  // 【解説】 [ for (...) 式 ] は collection-for。ループの各回の値でリストを作る。
  // 【解説】 this(自分)を子にも渡すので、見た目と差し替えが木の下まで届く。
  List<Widget> buildLayouts(BuildContext context, List<LayoutNode> nodes) => [
    for (final node in nodes) registry.buildLayout(context, node, this),
  ];

  /// Builds a widget for each of [nodes]: the lines, raw blocks and tables a
  /// block or a table cell holds.
  List<Widget> buildContents(BuildContext context, List<ContentNode> nodes) => [
    for (final node in nodes) registry.buildContent(context, node, this),
  ];
}

/// Which widget draws each kind of node.
///
/// A field per kind rather than a `Type`-keyed map: the node types are
/// sealed, so the set is closed and known here. Naming each one keeps the
/// builder's node type exact -- no cast on the way in, and a builder written
/// for the wrong kind does not compile.
class NaturalBlockRegistry {
  // 【解説】 既定値は 4 の描き方そのもの。差し替えたい種類だけ渡す。
  // 【解説】 トップレベル関数の名前は定数なので、既定値に書いても const のまま。
  final NodeBuilder<RowNode> row;

  final NodeBuilder<ColumnNode> column;

  final NodeBuilder<TableNode> table;

  final NodeBuilder<TableCellNode> tableCell;

  final NodeBuilder<TextNode> text;

  final NodeBuilder<RawNode> raw;

  // 【解説】 すべて省略できるので、既定の表は const で作れる。
  const NaturalBlockRegistry({
    this.row = buildRowNode,
    this.column = buildColumnNode,
    this.table = buildTableNode,
    this.tableCell = buildTableCellNode,
    this.text = buildTextNode,
    this.raw = buildRawNode,
  });

  static const NaturalBlockRegistry defaults = NaturalBlockRegistry();

  /// The widget for [node], a block or a row.
  // 【解説】 switch のパターン(RowNode() など)が型を絞るので、この中の node は
  // 【解説】 その型として扱える。キャストは要らない。
  // 【解説】 LayoutNode は sealed で中身はこの2つだけなので、これで網羅。
  Widget buildLayout(
    BuildContext context,
    LayoutNode node,
    NaturalBlockScope scope,
  ) => switch (node) {
    RowNode() => row(context, node, scope),
    ColumnNode() => column(context, node, scope),
  };

  /// The widget for [node], one of the things a block or a table cell holds.
  // 【解説】 入口を「ブロック・行」と「その中身」に分けてあるので、単体では
  // 【解説】 描かれないノード(文書・表の行・run)はそもそも渡せない。
  // 【解説】 表のセルは種類が1つしかないので、振り分けずに tableCell を直接呼ぶ。
  Widget buildContent(
    BuildContext context,
    ContentNode node,
    NaturalBlockScope scope,
  ) => switch (node) {
    TableNode() => table(context, node, scope),
    TextNode() => text(context, node, scope),
    RawNode() => raw(context, node, scope),
  };

  /// Two registries are equal when they name the same builder for every kind.
  ///
  /// Worth having because the view compares registries to decide whether the
  /// tree it drew is still good. A function written out as a literal is never
  /// equal to another, so a registry built inline in a `build` compares as
  /// changed every time -- which costs a rebuild, never correctness. Naming
  /// the builders (a top-level function, or a method on your state) makes
  /// this hold.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NaturalBlockRegistry &&
        row == other.row &&
        column == other.column &&
        table == other.table &&
        tableCell == other.tableCell &&
        text == other.text &&
        raw == other.raw;
  }

  @override
  int get hashCode => Object.hash(row, column, table, tableCell, text, raw);
}
