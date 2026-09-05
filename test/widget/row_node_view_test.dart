// 【解説】[テスト15/21] 横並び。Expanded を使う理由と、使えない場合。
// 【解説】
// 【解説】 セルを等分するのは、行ごとに独立して描かれるから。等分だけが
// 【解説】 行をまたいで列を揃える方法で、左^^右 が右端に寄るのもこれ。
// 【解説】
// 【解説】 幅が無限のとき(横スクロールの中や Row の入れ子)は分ける幅が
// 【解説】 無く、Expanded は使えない。内容に合わせて縮む方に落とす。
// 【解説】 これは同等の代替ではなく劣化で、列は揃わなくなり寄せも効かなく
// 【解説】 なる。それでも入れているのは、代わりが「描けない」だからで、
// 【解説】 テストの名前にもその判断が書いてある。
// 【解説】 次: test/widget/table_node_view_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

void main() {
  const theme = NaturalBlockTheme();
  const registry = NaturalBlockRegistry.defaults;

  group('RowNodeView', () {
    testWidgets(
      'gives each cell (ColumnNode) one Expanded, stacking a multi-line '
      "cell's lines vertically",
      (tester) async {
        final node = RowNode(
          children: [
            ColumnNode(
              children: [
                TextNode(children: [TextSpanNode(text: 'a')]),
                TextNode(children: [TextSpanNode(text: 'b')]),
              ],
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: RowNodeView(
              node: node,
              scope: NaturalBlockScope(theme: theme, registry: registry),
            ),
          ),
        );

        expect(find.byType(Row), findsOneWidget);
        expect(find.byType(Expanded), findsOneWidget);
        expect(find.byType(TextNodeView), findsNWidgets(2));

        // The two lines of the one cell are stacked.
        final column = tester.widget<Column>(
          find.descendant(
            of: find.byType(Expanded),
            matching: find.byType(Column),
          ),
        );
        expect(column.children, hasLength(2));
      },
    );

    testWidgets('renders one Expanded cell per ColumnNode child', (
      tester,
    ) async {
      final node = RowNode(
        children: [
          ColumnNode(
            children: [
              TextNode(children: [TextSpanNode(text: 'left')]),
            ],
          ),
          ColumnNode(
            children: [
              TextNode(children: [TextSpanNode(text: 'right')]),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RowNodeView(
            node: node,
            scope: NaturalBlockScope(theme: theme, registry: registry),
          ),
        ),
      );

      expect(find.byType(Row), findsOneWidget);
      expect(find.byType(Expanded), findsNWidgets(2));
    });

    testWidgets('an empty cell renders as an empty Expanded', (tester) async {
      final node = RowNode(
        children: [
          ColumnNode(
            children: [
              TextNode(children: [TextSpanNode(text: 'left')]),
            ],
          ),
          ColumnNode(children: []), // middle cell deliberately blank
          ColumnNode(
            children: [
              TextNode(children: [TextSpanNode(text: 'right')]),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RowNodeView(
            node: node,
            scope: NaturalBlockScope(theme: theme, registry: registry),
          ),
        ),
      );

      expect(find.byType(Expanded), findsNWidgets(3));
      expect(find.byType(TextNodeView), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('an empty RowNode renders an empty Row without throwing', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RowNodeView(
            node: RowNode(children: []),
            scope: NaturalBlockScope(theme: theme, registry: registry),
          ),
        ),
      );

      final row = tester.widget<Row>(find.byType(Row));
      expect(row.children, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'cells are built through the registry, so a custom builder applies '
      'to row cells too',
      (tester) async {
        final customRegistry = NaturalBlockRegistry.defaults.register(
          ColumnNode,
          (context, node, scope) => const Placeholder(),
        );
        final node = RowNode(
          children: [
            ColumnNode(children: [TextNode(children: [])]),
          ],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: RowNodeView(
              node: node,
              scope: NaturalBlockScope(theme: theme, registry: customRegistry),
            ),
          ),
        );

        expect(find.byType(Placeholder), findsOneWidget);
        expect(find.byType(ColumnNodeView), findsNothing);
      },
    );
  });
}
