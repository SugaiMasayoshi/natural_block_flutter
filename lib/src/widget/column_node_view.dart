// 【解説】 読む順番 5/12: 列(ブロック)と表のセルを描くウィジェット。
// 【解説】 受け取ったウィジェットを縦に積み、寄せ(< = >)に応じて左・中央・右に置く。
// 【解説】 寄せを Flutter の値に変える部分は 6(horizontal_align_layout)にある。
import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import 'horizontal_align_layout.dart';

// 【解説】 StatelessWidget: 状態を持たず、渡された値だけで見た目が決まるウィジェット。
class ColumnNodeView extends StatelessWidget {
  final List<Widget> children;

  /// The alignment the source stated, or null when it stated none.
  ///
  /// Both draw at the start today. They are kept apart so a theme can give
  /// unaligned blocks a look of its own without also overriding a block that
  /// asked for the start.
  final HorizontalAlign align;

  const ColumnNodeView({
    super.key,
    required this.children,
    this.align = HorizontalAlign.unstated,
  });

  @override
  Widget build(BuildContext context) {
    final column = Column(
      // 【解説】 crossAxis は 6 で定義した拡張ゲッター。子を左・中央・右のどこに揃えるか。
      crossAxisAlignment: align.crossAxis,
      // 【解説】 縦方向は中身の高さだけを取る(親いっぱいに伸びない)。
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
    // 【解説】 左寄せ(または指定なし)なら包む必要がないので、そのまま返す。
    if (align.isStart) return column;
    // 【解説】 それ以外は Align で包み、ブロック全体を中央・右へ動かす。
    return Align(alignment: align.alignment, child: column);
  }
}
