// 【解説】[12/16] 木の葉。TextNode を実際の文字として描く唯一の場所。
// 【解説】
// 【解説】 読みどころは3つ:
// 【解説】  1. RichText ではなく Text.rich を使っている。直接 RichText を組むと
// 【解説】     選択機構に登録されず、SelectionArea で囲んでも黙って選択できない
// 【解説】  2. StatefulWidget なのは TapGestureRecognizer が破棄の要る資源だから。
// 【解説】     ただし build で作り直さず、オブジェクトを再利用して onTap だけ
// 【解説】     差し替える。押下を受けた recognizer はジェスチャアリーナの
// 【解説】     エントリを持つので、押下と離上の間の再ビルドで作り直すと
// 【解説】     タップが黙って消える。クロージャは呼び出し時に widget を読むため
// 【解説】     「古いコールバックを掴む」心配は元々無かった
// 【解説】  3. onActionTap が null なら recognizer を作らない。作らなければ
// 【解説】     破棄すべきものも無い、という単純化
// 【解説】
// 【解説】 破棄そのものは今も検証できない(GestureRecognizer.dispose は印を残さない)。
// 【解説】 代わりに「再ビルドを跨いでも同じオブジェクトか」と「押下中の再ビルドを
// 【解説】 挟んでもタップが届くか」を検証している。後者は旧実装で実際に落ちる。
// 【解説】 次: lib/src/widget/column_node_view.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../registry/natural_block_registry.dart';
import 'natural_block_theme.dart';

/// Renders a [TextNode]'s [TextSpanNode] children as a single rich text
/// run, mapping each span's [SemanticColor], emphasis flag, and
/// `sizeOffset` onto [TextStyle] via [theme].
///
/// Built with [Text.rich] rather than a bare [RichText] so the result takes
/// part in text selection: a consumer who wraps a `NaturalBlockView` in a
/// `SelectionArea` gets selectable, copyable text, including drags that
/// cross cell and row boundaries. A directly-constructed [RichText] does
/// not register with the selection machinery and would be unselectable.
///
/// A [StatefulWidget] rather than stateless: a span with
/// `TextSpanNode.isAction == true` needs a [TapGestureRecognizer] attached
/// to its [TextSpan], and recognizers are disposable objects that must be
/// torn down explicitly -- something a stateless build method has nowhere
/// to do. The state rebuilds its recognizer list on every `build` (disposing
/// the previous batch first) and disposes whatever's left in `dispose()`.
class TextNodeView extends StatefulWidget {
  /// The node whose [TextNode.children] spans are rendered.
  final TextNode node;

  /// Styling used to turn each span's semantic color, emphasis, and
  /// `sizeOffset` into a concrete [TextStyle].
  final NaturalBlockTheme theme;

  /// What to do with this line's actionable runs: replace them with a span
  /// of the caller's own via [NaturalBlockActions.buildSpan], make them
  /// tappable via [NaturalBlockActions.onTap], or neither -- in which case
  /// they still render with [NaturalBlockTheme.action] but get no tap
  /// recognizer at all, so there is nothing to dispose.
  final NaturalBlockActions actions;

  const TextNodeView({
    super.key,
    required this.node,
    required this.theme,
    this.actions = NaturalBlockActions.none,
  });

  @override
  State<TextNodeView> createState() => _TextNodeViewState();
}

class _TextNodeViewState extends State<TextNodeView> {
  /// One recognizer per actionable span, reused across builds and indexed
  /// by the order those spans appear in.
  ///
  /// Reused, not rebuilt. A recognizer that has already taken a pointer
  /// down owns an entry in the gesture arena, so disposing it mid-gesture
  /// -- which any ancestor rebuild between the down and the up would do if
  /// `build` recreated these -- rejects that entry and the tap is silently
  /// lost. Rebuilds land there easily: an animation, an ambient
  /// [InheritedWidget] changing, a `SelectionArea` updating during a drag.
  ///
  /// Nothing is gained by recreating them either. The concern that a
  /// recognizer would hold a stale callback does not arise, because the
  /// closure assigned below reads `widget` when the tap happens rather
  /// than when it was built.
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
    super.dispose();
  }

  /// The recognizer for the [index]-th actionable span, creating it the
  /// first time that index is needed.
  TapGestureRecognizer _recognizerAt(int index) {
    while (_recognizers.length <= index) {
      _recognizers.add(TapGestureRecognizer());
    }
    return _recognizers[index];
  }

  /// Releases recognizers past [keep], for when a rebuild left this line
  /// with fewer actionable spans than before.
  void _trimRecognizers(int keep) {
    while (_recognizers.length > keep) {
      _recognizers.removeLast().dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    var actionIndex = 0;

    // A line whose only content is a verbatim region *is* that region, so
    // it is drawn the way anyone writing a code block expects: a padded
    // box, monospaced, its own thing on the page. A region sitting among
    // text is the same node in a different place, and gets the monospace
    // run without the box. The parser makes no distinction -- where it was
    // written is a question about appearance, so it is answered here.
    final children = widget.node.children;
    if (children.length == 1 && children.single is VerbatimNode) {
      return _VerbatimBlock(
        node: children.single as VerbatimNode,
        theme: widget.theme,
      );
    }

    final spans = widget.node.children.map<InlineSpan>((child) {
      if (child is VerbatimNode) {
        return TextSpan(
          text: child.text,
          style: DefaultTextStyle.of(context).style.merge(widget.theme.verbatim),
        );
      }
      final span = child as TextSpanNode;
      final style = widget.theme
          .styleFor(span.color)
          .merge(span.emphasis ? widget.theme.emphasis : null)
          .merge(span.isAction ? widget.theme.action : null)
          .copyWith(
            fontSize: span.sizeOffset != 0
                ? _fontSizeFor(context, span.sizeOffset)
                : null,
          );

      if (span.isAction) {
        // The caller gets first refusal on every actionable run. A span it
        // returns replaces the default rendering completely -- text, style
        // and gestures -- which is how a run can come out as something that
        // is not text at all, an image say. The style is handed over with
        // its font size already resolved, so the markup's own size
        // vocabulary can reach content that has no font size of its own.
        final built = widget.actions.buildSpan?.call(
          context,
          span.text,
          style.copyWith(fontSize: style.fontSize ?? _baseFontSize(context)),
          widget.theme,
        );
        if (built != null) return built;
      }

      GestureRecognizer? recognizer;
      final onTap = widget.actions.onTap;
      if (span.isAction && onTap != null) {
        final text = span.text;
        // Reused object, fresh callback. The closure reads `widget` at tap
        // time, so it can never be stale, and the recognizer keeps whatever
        // arena entry an in-flight gesture gave it.
        recognizer = _recognizerAt(actionIndex++)..onTap = () => onTap(text);
      }

      return TextSpan(
        text: span.text,
        style: style,
        recognizer: recognizer,
        // Announced as a link only when it actually does something. The
        // action *style* still follows the document -- it said the run is
        // actionable -- but claiming a link to a screen reader when no
        // handler is wired would be a promise nothing keeps.
        semanticsLabel: span.isAction && onTap != null ? span.text : null,
      );
    }).toList();

    _trimRecognizers(actionIndex);

    return Text.rich(
      TextSpan(
        style: DefaultTextStyle.of(context).style.merge(widget.theme.base),
        children: spans,
      ),
    );
  }

  /// The size a run with no size markup renders at: whatever is ambient, or
  /// the theme's fallback when nothing ambient says.
  ///
  /// Resolved explicitly rather than left null when handing a style to an
  /// [ActionSpanBuilder]: a builder rendering something that is not text
  /// has no way to recover the size otherwise, and `TextStyle.fontSize` is
  /// null for every unmarked run.
  double _baseFontSize(BuildContext context) =>
      DefaultTextStyle.of(context).style.fontSize ?? widget.theme.baseFontSize;

  /// Computes the font size for a span with a non-zero `sizeOffset`,
  /// scaling from [_baseFontSize] by [NaturalBlockTheme.fontSizeStep]
  /// points per step.
  ///
  /// The result is clamped to [NaturalBlockTheme.minFontSize] so a large
  /// negative offset (the parser supports e.g. `:-----`, an offset of -5)
  /// cannot drive the font size to zero or below, which Flutter's
  /// [TextStyle] asserts against.
  double _fontSizeFor(BuildContext context, int sizeOffset) {
    final ambient = _baseFontSize(context);
    final scaled = ambient + sizeOffset * widget.theme.fontSizeStep;
    return scaled < widget.theme.minFontSize
        ? widget.theme.minFontSize
        : scaled;
  }
}

/// A verbatim region that is a whole line, drawn as a code block.
///
/// Separate from the inline case only in presentation. The AST has one
/// verbatim node; whether it looks like a block is about where it was
/// written, which is a question only a renderer can answer.
class _VerbatimBlock extends StatelessWidget {
  final VerbatimNode node;
  final NaturalBlockTheme theme;

  const _VerbatimBlock({required this.node, required this.theme});

  @override
  Widget build(BuildContext context) {
    // Text.rich rather than a bare RichText, for the same reason the rest
    // of this file uses it: code is exactly the kind of text a reader wants
    // to select and copy.
    final content = Text.rich(
      TextSpan(
        text: node.text,
        style: DefaultTextStyle.of(context).style.merge(theme.verbatim),
      ),
      // Wrapping has to be off when scrolling, or the text would wrap to the
      // viewport and the scroll view would have nothing to scroll.
      softWrap: !theme.verbatimScrollsHorizontally,
    );

    return Container(
      padding: theme.verbatimPadding,
      decoration: theme.verbatimDecoration,
      // The box is never stretched to the available width, for the same
      // reason `ColumnNodeView` uses Align rather than a width-filling
      // SizedBox: adding a code block must not be able to stop a document
      // rendering where the width is unbounded.
      child: theme.verbatimScrollsHorizontally
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: content,
            )
          : content,
    );
  }
}
