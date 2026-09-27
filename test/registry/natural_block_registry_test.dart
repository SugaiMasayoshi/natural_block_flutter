import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

void main() {
  const theme = NaturalBlockTheme();

  Future<List<Widget>> buildWith(
    WidgetTester tester,
    NaturalBlockRegistry registry,
    List<NaturalBlockNode> nodes,
  ) async {
    late List<Widget> built;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            built = NaturalBlockScope(
              theme: theme,
              registry: registry,
            ).buildAll(context, nodes);
            return Column(children: built);
          },
        ),
      ),
    );
    return built;
  }

  TextNode text(String s) => TextNode(children: [TextSpanNode(text: s)]);

  group('NaturalBlockRegistry.defaults', () {
    testWidgets('default registry renders Row/Column/Text via their views', (
      tester,
    ) async {
      final nodes = <NaturalBlockNode>[
        RowNode(
          children: [
            ColumnNode(children: [text('a')]),
            ColumnNode(children: [text('b')]),
          ],
        ),
        ColumnNode(children: [text('c')]),
        text('d'),
      ];

      await buildWith(tester, NaturalBlockRegistry.defaults, nodes);

      expect(find.byType(RowNodeView), findsOneWidget);
      // One direct ColumnNode, and one for each of the RowNode's two cells.
      expect(find.byType(ColumnNodeView), findsNWidgets(3));
      // One direct TextNode, one in the top-level ColumnNode, and one in
      // each of the RowNode's cells.
      expect(find.byType(TextNodeView), findsNWidgets(4));
    });

    testWidgets(
      'one RowNode renders as one Row, keeping other nodes separate',
      (tester) async {
        final nodes = <NaturalBlockNode>[
          RowNode(
            children: [
              ColumnNode(children: [text('a')]),
              ColumnNode(children: [text('b')]),
            ],
          ),
          text('between'),
          RowNode(
            children: [
              ColumnNode(children: [text('c')]),
              ColumnNode(children: [text('d')]),
            ],
          ),
        ];

        final built = await buildWith(
          tester,
          NaturalBlockRegistry.defaults,
          nodes,
        );

        // 2 RowNodes + 1 plain text = 3 top-level widgets.
        expect(built.length, 3);
        expect(find.byType(RowNodeView), findsNWidgets(2));
        expect(find.byType(Row), findsNWidgets(2));
        expect(
          find.byType(Expanded),
          findsNWidgets(4),
        ); // a+b in one Row, c+d in the other
      },
    );

    testWidgets('a node never drawn on its own renders nothing', (
      tester,
    ) async {
      // A run and a table row reach a widget only through the line or table
      // that holds them, so asking for one directly draws an empty box.
      await buildWith(tester, NaturalBlockRegistry.defaults, [
        TextSpanNode(text: 'a'),
        TableRowNode(
          children: [
            TableCellNode(children: [text('b')]),
          ],
        ),
      ]);

      expect(tester.takeException(), isNull);
      expect(find.byType(TextNodeView), findsNothing);
      expect(find.text('a'), findsNothing);
    });
  });

  group('builders of your own', () {
    testWidgets('one replaces the default for that kind of node', (
      tester,
    ) async {
      final registry = NaturalBlockRegistry(
        text: (context, node, scope) => const Placeholder(),
      );

      await buildWith(tester, registry, [text('a')]);

      expect(find.byType(Placeholder), findsOneWidget);
      expect(find.byType(TextNodeView), findsNothing);
    });

    testWidgets(
      'a ColumnNode builder also applies to row cells, since cells are '
      'built through the registry',
      (tester) async {
        final registry = NaturalBlockRegistry(
          column: (context, node, scope) => const Placeholder(),
        );
        final nodes = <NaturalBlockNode>[
          RowNode(
            children: [
              ColumnNode(children: [text('a')]),
              ColumnNode(children: [text('b')]),
            ],
          ),
        ];

        await buildWith(tester, registry, nodes);

        expect(find.byType(Placeholder), findsNWidgets(2));
        expect(find.byType(TextNodeView), findsNothing);
      },
    );

    testWidgets('the kinds left out keep their default', (tester) async {
      final registry = NaturalBlockRegistry(
        text: (context, node, scope) => const Placeholder(),
      );

      await buildWith(tester, registry, [
        ColumnNode(children: [text('a')]),
      ]);

      expect(find.byType(ColumnNodeView), findsOneWidget);
      expect(find.byType(Placeholder), findsOneWidget);
    });
  });
}
