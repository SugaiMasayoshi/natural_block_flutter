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
  });

  group('register / registerAll (custom builders)', () {
    testWidgets('custom builder overrides the default for its node type', (
      tester,
    ) async {
      final registry = NaturalBlockRegistry.defaults.register(
        TextNode,
        (context, node, scope) => const Placeholder(),
      );
      final nodes = <NaturalBlockNode>[text('a')];

      await buildWith(tester, registry, nodes);

      expect(find.byType(Placeholder), findsOneWidget);
      expect(find.byType(TextNodeView), findsNothing);
    });

    testWidgets(
      'a custom ColumnNode builder also applies to row cells, since cells '
      'are built through the registry',
      (tester) async {
        final registry = NaturalBlockRegistry.defaults.register(
          ColumnNode,
          (context, node, scope) => const Placeholder(),
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

    testWidgets(
      'buildRowNode throws immediately when registered for a non-RowNode '
      'type, instead of silently misbehaving',
      (tester) async {
        final registry = NaturalBlockRegistry.defaults.register(
          TextNode,
          buildRowNode,
        );
        final nodes = <NaturalBlockNode>[text('a')];

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                NaturalBlockScope(
                  theme: theme,
                  registry: registry,
                ).buildAll(context, nodes);
                return const SizedBox();
              },
            ),
          ),
        );

        expect(tester.takeException(), isA<TypeError>());
      },
    );
  });

  group('NaturalBlockRegistry.empty', () {
    testWidgets('empty registry falls back to an empty box without throwing', (
      tester,
    ) async {
      final nodes = <NaturalBlockNode>[
        RowNode(children: [ColumnNode(), ColumnNode()]),
        ColumnNode(),
        text('a'),
      ];

      await buildWith(tester, const NaturalBlockRegistry.empty(), nodes);

      expect(tester.takeException(), isNull);
      expect(find.byType(RowNodeView), findsNothing);
      expect(find.byType(ColumnNodeView), findsNothing);
      expect(find.byType(TextNodeView), findsNothing);
    });
  });
}
