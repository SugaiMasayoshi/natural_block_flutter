// 【解説】 読む順番 8/12: 文章(TextNode)を1つの Text.rich として描くウィジェット。
// 【解説】 run ごとに装飾(色合い・強調・操作・大きさ)を TextStyle に変え、
// 【解説】 :@ の run には押したときの処理(タップ認識器)を付ける。
// 【解説】 認識器は後始末が要るので、状態を持つ StatefulWidget にしている。
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../registry/natural_block_registry.dart';
import 'natural_block_theme.dart';

class TextNodeView extends StatefulWidget {
  final TextNode node;

  final NaturalBlockScope scope;

  const TextNodeView({super.key, required this.node, required this.scope});

  @override
  State<TextNodeView> createState() => _TextNodeViewState();
}

class _TextNodeViewState extends State<TextNodeView> {
  // 【解説】 get 名前 => 式: 引数の無いゲッター。毎回 widget から読み直すので、設定が変わっても追従する。
  NaturalBlockTheme get _theme => widget.scope.theme;

  NaturalBlockActions get _actions => widget.scope.actions;

  /// What every run of this line starts from: the ambient style with the
  /// theme's `base` merged over it.
  ///
  /// One expression, because two of them is a bug rather than a repetition.
  /// The root span is built from this and so is the baseline a `:+` counts
  /// from; when they drifted apart, a theme whose `base` named a size made
  /// `:+` render *smaller* than the text beside it.
  // 【解説】 DefaultTextStyle.of(context): 祖先が決めた既定の文字の書式。
  // 【解説】 merge: 右の書式で指定がある項目だけ上書きした、新しい書式を作る。
  TextStyle _rootStyle(BuildContext context) =>
      DefaultTextStyle.of(context).style.merge(_theme.base);

  /// The recognizers for this line's actionable runs, kept across builds and
  /// keyed by the run's own text.
  ///
  /// Reused rather than rebuilt because a recognizer that has taken a pointer
  /// down owns an entry in the gesture arena; replacing it mid-gesture throws
  /// that entry away and the tap vanishes silently.
  ///
  /// Keyed by text because the text *is* the payload: `onTap` is handed the
  /// run's own text and nothing else, so two runs reading the same thing want
  /// the same recognizer, and a run keeps its own however the runs around it
  /// change. Keying by position instead would shift every later run onto a
  /// different recognizer whenever one before it was added or removed. The
  /// cost is the opposite case: editing a run's own text gives it a new
  /// recognizer, so a tap held across that edit is lost.
  // 【解説】 Map<鍵, 値>: 鍵から値を引ける入れ物。ここでは run の文字から認識器を引く。
  final Map<String, TapGestureRecognizer> _recognizers = {};

  // 【解説】 ウィジェットが画面から完全に外れるときに呼ばれる。認識器は必ず dispose する必要がある。
  @override
  void dispose() {
    for (final recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  /// The texts this line needs a recognizer for, and none at all when nothing
  /// is wired to them.
  // 【解説】 { for (...) ... } は集合(Set)のリテラル。同じ文字は自然に1つにまとまる。
  Set<String> get _actionTexts => _actions.onTap == null
      ? const {}
      : {
          for (final child in widget.node.children)
            if (child is TextSpanNode && child.decoration.isAction) child.text,
        };

  /// Makes the pool hold exactly [texts], keeping every recognizer already in
  /// it and disposing the ones no longer needed.
  // 【解説】 前回の build で作った物はそのまま残るので、使い回しになる。
  void _syncRecognizers(Set<String> texts) {
    // 【解説】 removeWhere: 条件に合う要素を消す。消す前に dispose しておく。
    _recognizers.removeWhere((text, recognizer) {
      if (texts.contains(text)) return false;
      recognizer.dispose();
      return true;
    });
    for (final text in texts) {
      // 【解説】 putIfAbsent: その鍵がまだ無いときだけ、右の関数で作って入れる。
      // 【解説】 onTap は作るとき一度だけ設定する。呼ばれた時点の _actions を読むので、
      // 【解説】 利用者が渡す関数が差し替わっても付け直す必要がない。
      _recognizers.putIfAbsent(
        text,
        () => TapGestureRecognizer()..onTap = () => _actions.onTap?.call(text),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // The pool is filled before the spans are built, so building one is only
    // a lookup by the run's own text.
    _syncRecognizers(_actionTexts);

    // 【解説】 map<InlineSpan>: 変換後の型を明示している。書かないと推論が片方の型に寄ることがある。
    final spans = widget.node.children.map<InlineSpan>((child) {
      // 【解説】 is: 型の判定。true の後はこのブロックの中で child が RawSpanNode として扱われる。
      if (child is RawSpanNode) return _rawSpan(context, child);
      final run = child as TextSpanNode;
      // 【解説】 押せる run なら自分の文字で認識器を引く。onTap が無ければプールが空で null。
      return _textSpan(
        context,
        run,
        run.decoration.isAction ? _recognizers[run.text] : null,
      );
    }).toList();

    // 【解説】 行全体の基準の書式を親の TextSpan に置き、各 run はその上に自分の書式を重ねる。
    return Text.rich(TextSpan(style: _rootStyle(context), children: spans));
  }

  // 【解説】 文中の raw は、祖先の既定の書式にテーマの raw 用の書式(等幅など)を重ねて描く。
  InlineSpan _rawSpan(BuildContext context, RawSpanNode node) => TextSpan(
    text: node.text,
    style: DefaultTextStyle.of(context).style.merge(_theme.raw),
  );

  /// The span for one styled run, or whatever [ActionSpanBuilder] returned
  /// for it. [recognizer] is this run's own, or null when the run is not
  /// actionable or nothing is wired to it.
  InlineSpan _textSpan(
    BuildContext context,
    TextSpanNode span,
    TapGestureRecognizer? recognizer,
  ) {
    // 【解説】 装飾を順に重ねて1つの書式にする。. で始まる行はメソッドの連鎖。
    final style = _theme
        // 【解説】 色合い(negative / positive / なし)に応じた書式から始める。
        .styleFor(span.decoration.tone)
        // 【解説】 merge(null) は何も変えない。強調なら強調の書式を重ねる。
        .merge(span.decoration.emphasis ? _theme.emphasis : null)
        .merge(span.decoration.isAction ? _theme.action : null)
        // 【解説】 copyWith: 指定した項目だけ差し替えた複製。null を渡した項目は元のまま。
        .copyWith(
          fontSize: span.decoration.sizeOffset != 0
              ? _fontSizeFor(context, span.decoration.sizeOffset)
              : null,
        );

    if (span.decoration.isAction) {
      // 【解説】 ?.call(...): buildSpan が null なら呼ばずに null、そうでなければ呼ぶ。
      final built = _actions.buildSpan?.call(
        context,
        span.text,
        // 【解説】 差し替える側が大きさを使えるよう、必ず具体的な大きさを入れて渡す。
        style.copyWith(fontSize: style.fontSize ?? _baseFontSize(context)),
        _theme,
      );
      // 【解説】 差し替えが何かを返したらそれを使う。null なら普通の文字として続きを描く。
      if (built != null) return built;
    }

    return TextSpan(
      text: span.text,
      style: style,
      recognizer: recognizer,
      // 【解説】 読み上げ用の文字。実際に押せる run のときだけ付ける。
      semanticsLabel: recognizer != null ? span.text : null,
    );
  }

  /// The size a run of this line draws at before any `:+` or `:-`.
  double _baseFontSize(BuildContext context) =>
      _rootStyle(context).fontSize ?? _theme.baseFontSize;

  // 【解説】 基準の大きさ + 段数 × 1段の幅。最小値を下回ったら最小値にする。
  double _fontSizeFor(BuildContext context, int sizeOffset) {
    final ambient = _baseFontSize(context);
    final scaled = ambient + sizeOffset * _theme.fontSizeStep;
    return scaled < _theme.minFontSize ? _theme.minFontSize : scaled;
  }
}
