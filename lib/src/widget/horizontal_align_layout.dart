// 【解説】 読む順番 6/12: パーサの寄せ(HorizontalAlign)を、Flutter の配置の値に変える。
// 【解説】 5(列)が使う。公開の export には入っていない、内部だけの部品。
import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

/// How a `HorizontalAlign` becomes Flutter layout.
///
/// Both views used to hold their own copy of this mapping, written once as a
/// `switch` statement and once as a switch expression, which made the
/// duplication easy to miss.
///
/// An unstated alignment draws at the start, which is a *drawing* decision:
/// the tree keeps it apart from `start` so a theme can tell them apart, and
/// this is where the two finally meet.
// 【解説】 extension ... on 型: 既存の型(ここではパーサの enum)に、外からメソッドやゲッターを足す。
// 【解説】 パーサのパッケージは Flutter を知らないので、Flutter 側の変換はこちらに置いている。
extension HorizontalAlignLayout on HorizontalAlign {
  /// Whether this needs no `Align` wrapper at all.
  // 【解説】 this は拡張している値そのもの(HorizontalAlign のどれか)。
  bool get isStart =>
      this == HorizontalAlign.unstated || this == HorizontalAlign.start;

  // 【解説】 switch 式: 値に応じて式を1つ選んで返す。すべての場合を書かないとコンパイルエラーになる。
  // 【解説】 A || B => は「A か B のとき」。指定なし(unstated)は左寄せ(start)と同じに描く。
  CrossAxisAlignment get crossAxis => switch (this) {
    HorizontalAlign.unstated ||
    HorizontalAlign.start => CrossAxisAlignment.start,
    HorizontalAlign.center => CrossAxisAlignment.center,
    HorizontalAlign.end => CrossAxisAlignment.end,
  };

  // 【解説】 AlignmentDirectional は文字の向きに従う(右から左の言語では start が右になる)。
  // 【解説】 中央は向きに関係ないので、普通の Alignment.center を使っている。
  AlignmentGeometry get alignment => switch (this) {
    HorizontalAlign.unstated ||
    HorizontalAlign.start => AlignmentDirectional.centerStart,
    HorizontalAlign.center => Alignment.center,
    HorizontalAlign.end => AlignmentDirectional.centerEnd,
  };
}
