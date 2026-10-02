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

  /// How this document looks, or null to take it from the ambient theme.
  ///
  /// Null rather than a constant default because no constant can be right in
  /// both a light and a dark theme -- the same reason `striped` is offered
  /// only on `fromColorScheme`. A fixed red reads on a light surface and
  /// muddies a dark one, so the default is derived from the surrounding
  /// `ColorScheme` instead of guessing.
  // 【解説】 null は「祖先のテーマ(Theme.of)から作る」。上書きしたいときだけ渡す。
  final NaturalBlockTheme? theme;

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
    this.theme,
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

  /// The tree last drawn, and what it was drawn from.
  ///
  /// Returning the very same widget object is what lets Flutter skip the
  /// whole subtree: `updateChild` stops at a child whose widget has not
  /// changed. `build` runs for reasons the tree owes nothing to -- an
  /// ancestor rebuilding, every frame of an animating parent -- and without
  /// this each of those redrew the document.
  // 【解説】 _cached が null でなく、かつ _drawnFrom が今回の鍵と等しければ、前回の木を返す。
  Widget? _cached;
  _DrawnFrom? _drawnFrom;

  /// The actions handed to the tree: a stand-in that reads the current widget
  /// when it fires.
  ///
  /// This is what keeps `onTap` out of the comparison below. A caller writes
  /// it as a closure in their own `build`, and two closures are never equal in
  /// Dart, so comparing it would miss every single time. Reading it at tap
  /// time instead means a cached tree still calls the newest callback.
  ///
  /// Null is passed through, because whether a run is tappable at all -- and
  /// so whether it is announced to a screen reader -- depends on it.
  NaturalBlockActions _liveActions() => NaturalBlockActions(
    onTap: widget.actions.onTap == null
        ? null
        : (text) => widget.actions.onTap!(text),
    buildSpan: widget.actions.buildSpan == null
        ? null
        : (context, text, style, theme) =>
              widget.actions.buildSpan!(context, text, style, theme),
  );

  @override
  Widget build(BuildContext context) {
    // 【解説】 テーマが渡されていなければ、祖先の配色から作る。
    final theme = widget.theme ?? NaturalBlockTheme.fromContext(context);

    // 【解説】 (a, b, c) はレコード。中身が等しければ == も等しくなるので、鍵にできる。
    // 【解説】 onTap は上の理由で入れず、「あるか無いか」だけを入れる。
    final from = (
      document: _document,
      theme: theme,
      registry: widget.registry,
      buildSpan: widget.actions.buildSpan,
      tappable: widget.actions.onTap != null,
    );

    if (_cached == null || from != _drawnFrom) {
      _drawnFrom = from;
      // 【解説】 見た目・差し替え・押したときの処理を1つにまとめ、木の下へ持ち回る(3)。
      final scope = NaturalBlockScope(
        theme: theme,
        registry: widget.registry,
        actions: _liveActions(),
      );
      // 【解説】 文書の子(列と行)をウィジェットに変え、文書全体を縦に積む。
      // 【解説】 寄せは指定しない(unstated)ので左詰め。
      _cached = ColumnNodeView(
        children: scope.buildLayouts(context, _document.children),
      );
    }

    return _cached!;
  }
}

/// What a drawn tree was drawn from, so the next `build` can tell whether it
/// still holds.
typedef _DrawnFrom = ({
  DocumentNode document,
  NaturalBlockTheme theme,
  NaturalBlockRegistry registry,
  ActionSpanBuilder? buildSpan,
  bool tappable,
});
