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

  /// Builds a widget for each of [nodes], whatever kind they are.
  // 【解説】 [ for (...) 式 ] は collection-for。ループの各回の値でリストを作る。
  // 【解説】 this(自分)を子にも渡すので、見た目と差し替えが木の下まで届く。
  List<Widget> buildAll(BuildContext context, List<NaturalBlockNode> nodes) => [
    for (final node in nodes) registry.build(context, node, this),
  ];
}

/// Which widget draws each kind of node.
///
/// A field per kind rather than a `Type`-keyed map: the node types are
/// sealed, so the set is closed and known here. Naming each one keeps the
/// builder's node type exact -- no cast on the way in, and a builder written
/// for the wrong kind does not compile.
class NaturalBlockRegistry {
  // 【解説】 null は「既定の描き方(4)を使う」。差し替えたい種類だけ渡す。
  final NodeBuilder<RowNode>? row;

  final NodeBuilder<ColumnNode>? column;

  final NodeBuilder<TableNode>? table;

  final NodeBuilder<TableCellNode>? tableCell;

  final NodeBuilder<TextNode>? text;

  final NodeBuilder<RawNode>? raw;

  // 【解説】 すべて省略できるので、既定の表は const で作れる。
  const NaturalBlockRegistry({
    this.row,
    this.column,
    this.table,
    this.tableCell,
    this.text,
    this.raw,
  });

  static const NaturalBlockRegistry defaults = NaturalBlockRegistry();

  /// The widget for [node], from this registry or the default for its kind.
  // 【解説】 switch のパターン(RowNode() など)が型を絞るので、この中の node は
  // 【解説】 その型として扱える。キャストは要らない。
  // 【解説】 ?? は「左が null なら右」。差し替えが無ければ既定の描き方を使う。
  // 【解説】 sealed なので、書き漏らした型があるとコンパイルエラーになる。
  Widget build(
    BuildContext context,
    NaturalBlockNode node,
    NaturalBlockScope scope,
  ) => switch (node) {
    RowNode() => (row ?? buildRowNode)(context, node, scope),
    ColumnNode() => (column ?? buildColumnNode)(context, node, scope),
    TableNode() => (table ?? buildTableNode)(context, node, scope),
    TableCellNode() => (tableCell ?? buildTableCellNode)(context, node, scope),
    TextNode() => (text ?? buildTextNode)(context, node, scope),
    RawNode() => (raw ?? buildRawNode)(context, node, scope),
    // 【解説】 ここに並ぶのは、単体では描かれないノード。文書は NaturalBlockView が、
    // 【解説】 表の行は表が、run は文章が、それぞれ自分の中で扱う。
    DocumentNode() ||
    TableRowNode() ||
    TextSpanNode() ||
    RawSpanNode() => const SizedBox.shrink(),
  };
}
