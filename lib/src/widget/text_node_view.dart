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

  /// This line's runs as spans, built once and kept until something they are
  /// made of changes.
  ///
  /// Not built in `build`, because `build` runs for reasons the spans owe
  /// nothing to -- an ancestor rebuilding, every frame of an animating
  /// parent. Rebuilding them there replaced the recognizers below on each of
  /// those, and a recognizer that has taken a pointer down owns an entry in
  /// the gesture arena: replace it mid-gesture and the tap vanishes silently.
  /// Keeping the spans is what keeps the recognizers.
  // 【解説】 late: 最初に読まれるまで初期化を遅らせる。didChangeDependencies で入れる。
  late List<InlineSpan> _spans;

  /// The recognizers the spans above carry, owned so they can be disposed.
  ///
  /// A flat list, because they are only ever created and released together
  /// with the spans -- there is no pool to keep in step with anything.
  final List<TapGestureRecognizer> _recognizers = [];

  /// Rebuilds the spans when an inherited widget they read changes.
  ///
  /// `DefaultTextStyle` is one: it decides what every run starts from, and it
  /// can change without this widget's own fields changing at all.
  // 【解説】 祖先の設定(InheritedWidget)が変わったときにフレームワークが呼ぶ。
  // 【解説】 最初の build の前にも必ず一度呼ばれるので、初期化もここで済む。
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _buildSpans();
  }

  /// Rebuilds the spans when what they are made of changes.
  ///
  /// `onTap`'s identity is deliberately not compared -- only whether it is
  /// null, which is what decides if a run carries a recognizer at all. The
  /// callback itself is read at tap time, so a caller writing a fresh closure
  /// on every build does not cost a rebuild here.
  @override
  void didUpdateWidget(TextNodeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget.scope;
    if (widget.node != oldWidget.node ||
        _theme != old.theme ||
        _actions.buildSpan != old.actions.buildSpan ||
        (_actions.onTap == null) != (old.actions.onTap == null)) {
      _buildSpans();
    }
  }

  // 【解説】 ウィジェットが画面から完全に外れるときに呼ばれる。認識器は必ず dispose する必要がある。
  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  /// Builds the spans, releasing the recognizers the previous ones carried.
  void _buildSpans() {
    _disposeRecognizers();
    // 【解説】 map<InlineSpan>: 変換後の型を明示している。書かないと推論が片方の型に寄ることがある。
    _spans = widget.node.children.map<InlineSpan>((child) {
      // 【解説】 is: 型の判定。true の後はこのブロックの中で child が RawSpanNode として扱われる。
      if (child is RawSpanNode) return _rawSpan(context, child);
      return _textSpan(context, child as TextSpanNode);
    }).toList();
  }

  /// A recognizer for a run reading [text], owned by this state.
  // 【解説】 onTap は作るとき一度だけ設定する。呼ばれた時点の _actions を読むので、
  // 【解説】 利用者が渡す関数が差し替わっても付け直す必要がない。
  TapGestureRecognizer _recognizerFor(String text) {
    final recognizer = TapGestureRecognizer()
      ..onTap = () => _actions.onTap?.call(text);
    _recognizers.add(recognizer);
    return recognizer;
  }

  @override
  Widget build(BuildContext context) =>
      // 【解説】 行全体の基準の書式を親の TextSpan に置き、各 run はその上に自分の書式を重ねる。
      Text.rich(TextSpan(style: _rootStyle(context), children: _spans));

  // 【解説】 文中の raw は、祖先の既定の書式にテーマの raw 用の書式(等幅など)を重ねて描く。
  InlineSpan _rawSpan(BuildContext context, RawSpanNode node) => TextSpan(
    text: node.text,
    style: DefaultTextStyle.of(context).style.merge(_theme.raw),
  );

  /// The span for one styled run, or whatever [ActionSpanBuilder] returned
  /// for it.
  InlineSpan _textSpan(BuildContext context, TextSpanNode span) {
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

    // 【解説】 押せて、かつ押したときの処理があるときだけ認識器を作る。
    // 【解説】 差し替えで描かれた run はここに来ないので、無駄な認識器も作られない。
    final recognizer = span.decoration.isAction && _actions.onTap != null
        ? _recognizerFor(span.text)
        : null;

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
