// 【解説】 読む順番 9/12: 行に独立して書いた raw 区間(コードブロック)を描くウィジェット。
// 【解説】 等幅などの書式・余白・背景で囲み、設定によっては横スクロールさせる。
import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import 'natural_block_theme.dart';

class RawNodeView extends StatelessWidget {
  final RawNode node;
  final NaturalBlockTheme theme;

  const RawNodeView({super.key, required this.node, required this.theme});

  @override
  Widget build(BuildContext context) {
    final content = Text.rich(
      TextSpan(
        text: node.text,
        style: DefaultTextStyle.of(context).style.merge(theme.raw),
      ),
      // 【解説】 ! は bool の否定。横スクロールするときは折り返さない。
      softWrap: !theme.rawScrollsHorizontally,
    );

    // 【解説】 Container: 余白(padding)と背景・角丸(decoration)をまとめて付ける箱。
    return Container(
      padding: theme.rawPadding,
      decoration: theme.rawDecoration,
      child: theme.rawScrollsHorizontally
          // 【解説】 横方向にスクロールできる領域で包む。長い行を折り返さずに見せる。
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: content,
            )
          : content,
    );
  }
}
