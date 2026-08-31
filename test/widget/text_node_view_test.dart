import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

void main() {
  group('color and emphasis', () {
    testWidgets('renders each TextSpanNode with its semantic style', (
      tester,
    ) async {
      final node = TextNode(
        children: [
          TextSpanNode(text: 'danger', color: SemanticColor.danger),
          TextSpanNode(text: 'plain'),
        ],
      );
      const theme = NaturalBlockTheme();

      await tester.pumpWidget(
        MaterialApp(
          home: TextNodeView(node: node, theme: theme),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final root = richText.text as TextSpan;
      final spans = root.children!.cast<TextSpan>();

      expect(spans[0].text, 'danger');
      expect(spans[0].style!.color, theme.danger.color);
      expect(spans[1].text, 'plain');
    });

    testWidgets('combines color and emphasis on the same span', (
      tester,
    ) async {
      final node = TextNode(
        children: [
          TextSpanNode(
            text: 'urgent',
            color: SemanticColor.danger,
            emphasis: true,
          ),
        ],
      );
      const theme = NaturalBlockTheme();

      await tester.pumpWidget(
        MaterialApp(home: TextNodeView(node: node, theme: theme)),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final root = richText.text as TextSpan;
      final span = root.children!.cast<TextSpan>().first;

      expect(span.style!.color, theme.danger.color);
      expect(span.style!.fontWeight, theme.emphasis.fontWeight);
    });
  });

  group('font size scaling', () {
    testWidgets('applies sizeOffset relative to the ambient font size', (
      tester,
    ) async {
      final node = TextNode(
        children: [TextSpanNode(text: 'big', sizeOffset: 2)],
      );
      const theme = NaturalBlockTheme();

      await tester.pumpWidget(
        MaterialApp(
          home: DefaultTextStyle(
            style: const TextStyle(fontSize: 14),
            child: TextNodeView(node: node, theme: theme),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final root = richText.text as TextSpan;
      final span = root.children!.cast<TextSpan>().first;

      expect(span.style!.fontSize, 14 + 2 * theme.fontSizeStep);
    });

    testWidgets(
      'clamps a large negative sizeOffset to minFontSize instead of '
      'producing a zero or negative font size',
      (tester) async {
        final node = TextNode(
          children: [TextSpanNode(text: 'tiny', sizeOffset: -5)],
        );
        const theme = NaturalBlockTheme();

        await tester.pumpWidget(
          MaterialApp(
            home: DefaultTextStyle(
              style: const TextStyle(fontSize: 14),
              child: TextNodeView(node: node, theme: theme),
            ),
          ),
        );

        expect(tester.takeException(), isNull);

        final richText = tester.widget<RichText>(find.byType(RichText));
        final root = richText.text as TextSpan;
        final span = root.children!.cast<TextSpan>().first;

        expect(span.style!.fontSize, theme.minFontSize);
        expect(span.style!.fontSize, greaterThan(0));
      },
    );
  });
}
