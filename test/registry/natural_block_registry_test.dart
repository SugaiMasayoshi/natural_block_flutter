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
            built = registry.buildAll(context, nodes, theme);
            return Column(children: built);
          },
        ),
      ),
    );
    return built;
  }

  group('NaturalBlockRegistry.defaults', () {
    testWidgets('default registry renders Row/Column/Text via their views', (
      tester,
    ) async {
      final nodes = <NaturalBlockNode>[
        RowNode(children: [TextNode(children: [TextSpanNode(text: 'a')])]),
        ColumnNode(children: [TextNode(children: [TextSpanNode(text: 'b')])]),
        TextNode(children: [TextSpanNode(text: 'c')]),
      ];

      await buildWith(tester, NaturalBlockRegistry.defaults, nodes);

      expect(find.byType(RowNodeView), findsOneWidget);
      expect(find.byType(ColumnNodeView), findsOneWidget);
      // One direct TextNode, one nested in ColumnNode, one nested in RowNode.
      expect(find.byType(TextNodeView), findsNWidgets(3));
    });

    testWidgets(
      'buildRowNode merges consecutive RowNode siblings into one Row, '
      'but keeps non-adjacent groups separate',
      (tester) async {
        final nodes = <NaturalBlockNode>[
          RowNode(children: [TextNode(children: [TextSpanNode(text: 'a')])]),
          RowNode(children: [TextNode(children: [TextSpanNode(text: 'b')])]),
          TextNode(children: [TextSpanNode(text: 'between')]),
          RowNode(children: [TextNode(children: [TextSpanNode(text: 'c')])]),
        ];

        final built = await buildWith(
          tester,
          NaturalBlockRegistry.defaults,
          nodes,
        );

        // 2 Row groups + 1 plain text = 3 top-level widgets, not 4.
        expect(built.length, 3);
        expect(find.byType(RowNodeView), findsNWidgets(2));
        expect(find.byType(Row), findsNWidgets(2));
        expect(find.byType(Expanded), findsNWidgets(3)); // a+b in one Row, c alone in the other
      },
    );
  });

  group('register / registerAll (custom builders)', () {
    testWidgets('custom builder overrides the default for its node type', (
      tester,
    ) async {
      final registry = NaturalBlockRegistry.defaults.register(
        TextNode,
        (context, siblings, index, theme, registry) =>
            const NodeBuildResult(widget: Placeholder()),
      );
      final nodes = <NaturalBlockNode>[TextNode(children: [])];

      await buildWith(tester, registry, nodes);

      expect(find.byType(Placeholder), findsOneWidget);
      expect(find.byType(TextNodeView), findsNothing);
    });

    testWidgets('a builder can consume multiple siblings', (tester) async {
      final registry = NaturalBlockRegistry.defaults.register(TextNode, (
        context,
        siblings,
        index,
        theme,
        registry,
      ) {
        final isFirstOfPair =
            index + 1 < siblings.length && siblings[index + 1] is TextNode;
        if (isFirstOfPair) {
          return const NodeBuildResult(
            widget: Placeholder(),
            consumedCount: 2,
          );
        }
        return buildTextNode(context, siblings, index, theme, registry);
      });
      final nodes = <NaturalBlockNode>[
        TextNode(children: []),
        TextNode(children: []),
        TextNode(children: []),
      ];

      final built = await buildWith(tester, registry, nodes);

      expect(built.length, 2); // pair merged into one + one remaining
      expect(find.byType(Placeholder), findsOneWidget);
      expect(find.byType(TextNodeView), findsOneWidget);
    });

    testWidgets(
      'buildRowNode throws immediately when registered for a non-RowNode '
      'type, instead of silently returning consumedCount: 0 (which would '
      'spin buildAll\'s loop forever in release mode)',
      (tester) async {
        final registry = NaturalBlockRegistry.defaults.register(
          TextNode,
          buildRowNode,
        );
        final nodes = <NaturalBlockNode>[TextNode(children: [])];

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                registry.buildAll(context, nodes, theme);
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
        RowNode(children: []),
        ColumnNode(children: []),
        TextNode(children: []),
      ];

      await buildWith(tester, const NaturalBlockRegistry.empty(), nodes);

      expect(tester.takeException(), isNull);
      expect(find.byType(RowNodeView), findsNothing);
      expect(find.byType(ColumnNodeView), findsNothing);
      expect(find.byType(TextNodeView), findsNothing);
    });
  });
}
