// 【解説】[番外3] verbatim（そのまま出す）区間の描画。
// 【解説】
// 【解説】 パーサ側で既に解釈を止めているので、ここは受け取った文字列を
// 【解説】 等幅で置くだけ。スパンも装飾も無い。
// 【解説】
// 【解説】 読みどころは横スクロールの扱い。コードは折り返すと別のプログラムに
// 【解説】 見えるので本来はスクロールが正しいが、有効にするとこのパッケージが
// 【解説】 初めてレイアウトの中にスクロールを持ち込むことになる。だから既定は
// 【解説】 折り返しで、テーマで切り替える形にした。
// 【解説】
// 【解説】 幅を明示的に広げていないのも意図的。幅いっぱいに広げると幅が無限の
// 【解説】 文脈で例外になる。寄せで SizedBox ではなく Align を選んだのと同じ判断。

import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import 'natural_block_theme.dart';

/// Renders one [VerbatimNode] -- text the parser deliberately stopped
/// reading -- as monospaced content in a box.
///
/// There is nothing to interpret here. The parser has already decided that
/// every character between the fences is content, so this widget only has
/// to avoid undoing that: no spans, no styling per run, and whitespace and
/// newlines exactly as they arrived.
///
/// ## Wrapping, and why scrolling is not the default
///
/// Wrapping is the wrong shape for code -- a line broken in the middle
/// reads as a different program -- so
/// [NaturalBlockTheme.verbatimScrollsHorizontally] exists. It is off by
/// default because turning it on puts a scroll view inside the caller's
/// layout, which nothing else in this package does, and a scroll view
/// nested in another scrollable is a well-known way to get a broken feel.
///
/// The box is also never stretched to the available width. A width-filling
/// box throws where the available width is unbounded, and the same
/// reasoning that made `ColumnNodeView` use [Align] instead of a
/// width-filling `SizedBox` applies here: adding a code block must not be
/// able to stop a document rendering.
class VerbatimNodeView extends StatelessWidget {
  /// The region to render. Its text is shown exactly as the parser
  /// produced it.
  final VerbatimNode node;

  /// Supplies the monospaced style, the padding, the box, and whether the
  /// content scrolls sideways.
  final NaturalBlockTheme theme;

  const VerbatimNodeView({
    super.key,
    required this.node,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    // Text.rich rather than a bare RichText, for the same reason
    // `TextNodeView` uses it: a directly-constructed RichText never
    // registers with the selection machinery, and code is exactly the kind
    // of text a reader wants to copy.
    final content = Text.rich(
      TextSpan(
        text: node.text,
        style: DefaultTextStyle.of(context).style.merge(theme.verbatim),
      ),
      // Wrapping has to be off when scrolling, or the text would wrap to
      // the viewport and the scroll view would have nothing to scroll.
      softWrap: !theme.verbatimScrollsHorizontally,
    );

    return Container(
      padding: theme.verbatimPadding,
      decoration: theme.verbatimDecoration,
      child: theme.verbatimScrollsHorizontally
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: content,
            )
          : content,
    );
  }
}
