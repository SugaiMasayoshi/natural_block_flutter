import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

import '../rendered_spans.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: DefaultTextStyle(
      style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
      child: child,
    ),
  );

  testWidgets('a table of one row, or one column, still renders', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const NaturalBlockView(
          source: '~only^row~',
          theme: NaturalBlockTheme(tableStripe: Color(0xFFEEEEEE)),
        ),
      ),
    );

    expect(
      tester.widget<Table>(find.byType(Table)).children.single.decoration,
      isNull,
    );

    await tester.pumpWidget(
      wrap(
        TableNodeView(
          node: TableNode(
            children: [
              TableRowNode(
                children: [
                  TableCellNode(
                    children: [
                      TextNode(children: [TextSpanNode(text: 'only')]),
                    ],
                  ),
                ],
              ),
            ],
          ),
          scope: const NaturalBlockScope(),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.widget<Table>(find.byType(Table)).children.single.children,
      hasLength(1),
    );
  });

  group('builders', () {
    testWidgets('cells are built through the builders', (tester) async {
      final builders = NaturalBlockBuilders(
        tableCell: (node, scope) => const Placeholder(),
      );

      await tester.pumpWidget(
        wrap(
          TableNodeView(
            node: TableNode(
              children: [
                TableRowNode(
                  children: [
                    TableCellNode(children: []),
                    TableCellNode(),
                  ],
                ),
              ],
            ),
            scope: NaturalBlockScope(builders: builders),
          ),
        ),
      );

      expect(find.byType(Placeholder), findsNWidgets(2));
    });

    testWidgets('a custom span inside a table cell is tappable', (
      tester,
    ) async {
      final tapped = <String>[];
      await tester.pumpWidget(
        wrap(
          NaturalBlockView(
            source: '~:@tap:@^B|C^D~',
            customs: [
              (text, style, theme) =>
                  tappableText(text, style, onTap: tapped.add),
            ],
          ),
        ),
      );

      final span = renderedSpans(tester).single;
      expect(span.text, 'tap');
      (span.recognizer! as TapGestureRecognizer).onTap!();

      expect(tapped, ['tap']);
    });
  });
}
