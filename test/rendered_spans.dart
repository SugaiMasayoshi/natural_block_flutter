import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The leaf `TextSpan`s carrying text, rendered by the [index]-th `RichText`.
/// Walks the span tree rather than indexing into it at a fixed depth.
List<TextSpan> renderedSpans(WidgetTester tester, {int index = 0}) {
  final richText = tester.widget<RichText>(find.byType(RichText).at(index));
  final leaves = <TextSpan>[];
  void walk(InlineSpan span) {
    if (span is! TextSpan) return;
    if (span.text != null) leaves.add(span);
    span.children?.forEach(walk);
  }

  walk(richText.text);
  return leaves;
}
