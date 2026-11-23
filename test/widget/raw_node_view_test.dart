import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

import '../rendered_spans.dart';

void main() {
  testWidgets('a raw block takes the size of the decoration it opens in', (
    tester,
  ) async {
    const theme = NaturalBlockTheme(base: TextStyle(fontSize: 20));
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            RawNodeView(
              node: RawNode(text: 'plain'),
              theme: theme,
            ),
            RawNodeView(
              node: RawNode(
                text: 'larger',
                decoration: const SpanDecoration(sizeOffset: 2),
              ),
              theme: theme,
            ),
          ],
        ),
      ),
    );

    final plain = renderedSpans(tester).single.style!;
    final larger = renderedSpans(tester, index: 1).single.style!;
    expect(plain.fontSize, 20);
    expect(plain.fontFamily, 'monospace');
    expect(
      larger.fontSize,
      theme
          .styleFor(const SpanDecoration(sizeOffset: 2), baseSize: 20)
          .fontSize,
    );
    expect(larger.fontFamily, 'monospace');
  });
}
