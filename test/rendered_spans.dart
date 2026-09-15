import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// The leaf [TextSpan]s -- the ones actually carrying text -- rendered by
/// the [index]-th `RichText` in the tree.
///
/// Walks the whole span tree instead of indexing into it at a fixed depth.
/// `Text.rich` nests the span it is given under a wrapper carrying the
/// ambient [DefaultTextStyle], and `TextNodeView` adds another for the
/// theme's base style, so the leaves sit two levels down today -- but that
/// is Flutter's business, not something a test asserting on *text and
/// style* should be coupled to.
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
