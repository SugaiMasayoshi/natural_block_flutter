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

  // 【解説】 :@ の run に付けるタップ認識器。使い回すため、番号順にリストで持つ。
  final List<TapGestureRecognizer> _recognizers = [];

  // 【解説】 ウィジェットが画面から完全に外れるときに呼ばれる。認識器は必ず dispose する必要がある。
  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  // 【解説】 index 番目の認識器を返す。足りなければ作って足す(前回の build で作った物は使い回す)。
  TapGestureRecognizer _recognizerAt(int index) {
    while (_recognizers.length <= index) {
      _recognizers.add(TapGestureRecognizer());
    }
    return _recognizers[index];
  }

  // 【解説】 今回使った数(keep)より多い分を後ろから捨てる。:@ の run が減ったときの後始末。
  void _trimRecognizers(int keep) {
    while (_recognizers.length > keep) {
      _recognizers.removeLast().dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Recognizers are numbered across the whole line and reclaimed by count,
    // so the tally is issued and collected in the same place. A span that
    // needs one asks for the next number; `_trimRecognizers` disposes the
    // rest.
    // 【解説】 この build で使った認識器の数。下の関数(クロージャ)が増やしていく。
    var actionIndex = 0;

    // 【解説】 map<InlineSpan>: 変換後の型を明示している。書かないと推論が片方の型に寄ることがある。
    final spans = widget.node.children.map<InlineSpan>((child) {
      // 【解説】 is: 型の判定。true の後はこのブロックの中で child が RawSpanNode として扱われる。
      if (child is RawSpanNode) return _rawSpan(context, child);
      // 【解説】 () => actionIndex++ は「呼ぶたびに今の番号を返してから1増やす」関数。
      // 【解説】 外の変数 actionIndex を閉じ込めて(クロージャ)いるので、呼ばれた分だけ数が進む。
      return _textSpan(context, child as TextSpanNode, () => actionIndex++);
    }).toList();

    // 【解説】 map は遅延評価なので、toList() の後で初めて actionIndex が確定する。その数まで残して捨てる。
    _trimRecognizers(actionIndex);

    // 【解説】 行全体の基準の書式を親の TextSpan に置き、各 run はその上に自分の書式を重ねる。
    return Text.rich(TextSpan(style: _rootStyle(context), children: spans));
  }

  // 【解説】 文中の raw は、祖先の既定の書式にテーマの raw 用の書式(等幅など)を重ねて描く。
  InlineSpan _rawSpan(BuildContext context, RawSpanNode node) => TextSpan(
    text: node.text,
    style: DefaultTextStyle.of(context).style.merge(_theme.raw),
  );

  /// The span for one styled run, or whatever [ActionSpanBuilder] returned
  /// for it. [nextAction] hands out the next recognizer number, and is only
  /// called when a recognizer is actually taken.
  InlineSpan _textSpan(
    BuildContext context,
    TextSpanNode span,
    // 【解説】 int Function() は「引数なしで int を返す関数」の型。
    int Function() nextAction,
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

    // 【解説】 ? 付きの型は null を入れられる。押せない run では null のまま。
    GestureRecognizer? recognizer;
    // 【解説】 一度ローカル変数に取り出すと、以降この変数は null でないと Dart が判断できる。
    final onTap = _actions.onTap;
    if (span.decoration.isAction && onTap != null) {
      final text = span.text;
      // 【解説】 ..onTap = ...: カスケード。左の認識器に onTap を設定し、認識器そのものを返す。
      recognizer = _recognizerAt(nextAction())..onTap = () => onTap(text);
    }

    return TextSpan(
      text: span.text,
      style: style,
      recognizer: recognizer,
      // 【解説】 読み上げ用の文字。押せる run のときだけ付ける。
      semanticsLabel: span.decoration.isAction && onTap != null
          ? span.text
          : null,
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
