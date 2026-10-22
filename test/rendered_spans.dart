// 【解説】読む順番 1/9：共通の補助。多くのテストが使う renderedSpans だけなので最初に。
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// 【解説】テスト共通の補助。画面の index 番目の RichText から、文字を持つ TextSpan だけを
// 【解説】順に取り出す。span は「行の根 → 各 run」と入れ子なので、深さを決め打ちせず葉まで辿る。
/// The leaf `TextSpan`s carrying text, rendered by the [index]-th `RichText`.
/// Walks the span tree rather than indexing into it at a fixed depth.
List<TextSpan> renderedSpans(WidgetTester tester, {int index = 0}) {
  final richText = tester.widget<RichText>(find.byType(RichText).at(index));
  final leaves = <TextSpan>[];
  // 【解説】関数の中に書いた関数（局所関数）。TextSpan 以外（WidgetSpan など）は無視する。
  void walk(InlineSpan span) {
    if (span is! TextSpan) return;
    if (span.text != null) leaves.add(span);
    // 【解説】`?.` は children が null なら何もしない。`forEach(walk)` は各子に walk を呼ぶ
    // 【解説】（関数を呼ばずにそのまま渡す書き方）。
    span.children?.forEach(walk);
  }

  walk(richText.text);
  return leaves;
}
