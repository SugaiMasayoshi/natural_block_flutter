import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

void main() {
  group('RowNodeView', () {
    testWidgets(
      'wraps each RowNode child in Expanded and ignores non-TextNode content',
      (tester) async {
        final node = RowNode(
          children: [
            TextNode(children: [TextSpanNode(text: 'a')]),
            TextSpanNode(text: 'x'), // non-TextNode child: filtered out
            TextNode(children: [TextSpanNode(text: 'b')]),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: RowNodeView(nodes: [node], theme: const NaturalBlockTheme()),
          ),
        );

        expect(find.byType(Row), findsOneWidget);
        expect(find.byType(Expanded), findsNWidgets(2));
        expect(find.byType(TextNodeView), findsNWidgets(2));
      },
    );

    testWidgets('merges multiple RowNodes into one Row, one cell each', (
      tester,
    ) async {
      final nodes = [
        RowNode(children: [TextNode(children: [TextSpanNode(text: 'left')])]),
        RowNode(children: [TextNode(children: [TextSpanNode(text: 'right')])]),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: RowNodeView(nodes: nodes, theme: const NaturalBlockTheme()),
        ),
      );

      expect(find.byType(Row), findsOneWidget);
      expect(find.byType(Expanded), findsNWidgets(2));
    });

    testWidgets('an empty nodes list renders an empty Row without throwing', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RowNodeView(nodes: const [], theme: const NaturalBlockTheme()),
        ),
      );

      final row = tester.widget<Row>(find.byType(Row));
      expect(row.children, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });
}
