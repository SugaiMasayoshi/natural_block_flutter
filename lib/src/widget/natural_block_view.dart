// 【解説】 読む順番 2/12: 利用者が画面に置くウィジェット。
// 【解説】 マークアップの文字列を受け取り、パースして木にし、木の各ノードを
// 【解説】 レジストリ(3)で選んだウィジェットに変えて縦に並べる。
import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../registry/natural_block_registry.dart';
import 'column_node_view.dart';
import 'natural_block_theme.dart';

// 【解説】 StatefulWidget: 状態(ここではパース済みの木)を持てるウィジェット。
// 【解説】 ウィジェット本体は設定の入れ物で、状態は下の _NaturalBlockViewState が持つ。
class NaturalBlockView extends StatefulWidget {
  // 【解説】 表示するマークアップの文字列。
  final String source;

  // 【解説】 色・大きさ・表の罫線などの見た目の設定(11)。
  final NaturalBlockTheme theme;

  // 【解説】 ノードの種類ごとに、どのウィジェットで描くかの差し替え(3)。
  final NaturalBlockRegistry registry;

  // 【解説】 :@ を押したときの処理と、:@ を独自に描く関数(3)。
  final NaturalBlockActions actions;

  // 【解説】 const コンストラクタ: 引数がすべて定数なら、コンパイル時に1つだけ作られる。
  const NaturalBlockView({
    // 【解説】 super.key: 受け取った key を親クラス(Widget)のコンストラクタへそのまま渡す短縮記法。
    super.key,
    // 【解説】 required: 名前付き引数だが省略できない。
    required this.source,
    // 【解説】 this.theme = ...: 渡されなければ既定値を使う。既定値は定数である必要がある。
    this.theme = const NaturalBlockTheme(),
    this.registry = NaturalBlockRegistry.defaults,
    this.actions = NaturalBlockActions.none,
  });

  // 【解説】 StatefulWidget が状態オブジェクトを作る場所。フレームワークが一度だけ呼ぶ。
  @override
  State<NaturalBlockView> createState() => _NaturalBlockViewState();
}

// 【解説】 名前が _ で始まるのでこのファイルの外からは見えない。
class _NaturalBlockViewState extends State<NaturalBlockView> {
  /// The parsed `source`, kept across rebuilds.
  ///
  /// The tree is a pure function of `source` and owes nothing to the
  /// `BuildContext`, but `build` runs whenever an ancestor rebuilds -- a
  /// theme change, a `MediaQuery` change, every frame of an animating
  /// parent. Parsing there charged the whole document to each of those.
  // 【解説】 late + 初期化式: 最初に読まれたときに一度だけ式を評価する。
  // 【解説】 State のフィールド初期化の時点では widget がまだ使えないため、late で遅らせている。
  late DocumentNode _document = NaturalBlockParser.parse(widget.source);

  // 【解説】 親が新しい設定で作り直したときに呼ばれる。oldWidget は前の設定。
  @override
  void didUpdateWidget(NaturalBlockView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 【解説】 文字列が変わったときだけパースし直す。見た目の設定だけの変更では木は同じ。
    if (widget.source != oldWidget.source) {
      _document = NaturalBlockParser.parse(widget.source);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 【解説】 見た目・差し替え・押したときの処理を1つにまとめ、木の下へ持ち回る(3)。
    final scope = NaturalBlockScope(
      theme: widget.theme,
      registry: widget.registry,
      actions: widget.actions,
    );

    // 【解説】 文書の子(列と行)を、それぞれの種類に応じたウィジェットに変える。
    final children = scope.buildLayouts(context, _document.children);

    // 【解説】 文書全体を縦に積む。寄せは指定しない(unstated)ので左詰め。
    return ColumnNodeView(children: children);
  }
}
