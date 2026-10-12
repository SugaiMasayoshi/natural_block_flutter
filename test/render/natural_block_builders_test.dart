import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

Widget _row(RowNode node, NaturalBlockScope scope) => const SizedBox();
Widget _column(ColumnNode node, NaturalBlockScope scope) => const SizedBox();
Widget _table(TableNode node, NaturalBlockScope scope) => const SizedBox();
Widget _tableCell(TableCellNode node, NaturalBlockScope scope) =>
    const SizedBox();
Widget _text(TextNode node, NaturalBlockScope scope) => const SizedBox();
Widget _raw(RawNode node, NaturalBlockScope scope) => const SizedBox();

void main() {
  const theme = NaturalBlockTheme();

  group('NaturalBlockBuilders equality', () {
    const variants = <String, NaturalBlockBuilders>{
      'row': NaturalBlockBuilders(row: _row),
      'column': NaturalBlockBuilders(column: _column),
      'table': NaturalBlockBuilders(table: _table),
      'tableCell': NaturalBlockBuilders(tableCell: _tableCell),
      'text': NaturalBlockBuilders(text: _text),
      'raw': NaturalBlockBuilders(raw: _raw),
    };

    for (final entry in variants.entries) {
      test('${entry.key} is part of equality', () {
        expect(entry.value, isNot(NaturalBlockBuilders.defaults));
        expect(
          entry.value,
          isNot(variants.values.firstWhere((v) => v != entry.value)),
        );
      });
    }

    test('equal builders hash alike', () {
      expect(
        const NaturalBlockBuilders(row: _row).hashCode,
        const NaturalBlockBuilders(row: _row).hashCode,
      );
    });
  });

  Future<List<Widget>> buildWith(
    WidgetTester tester,
    NaturalBlockBuilders builders,
    List<Widget> Function(NaturalBlockScope scope) build,
  ) async {
    final built = build(NaturalBlockScope(theme: theme, builders: builders));
    await tester.pumpWidget(MaterialApp(home: Column(children: built)));
    return built;
  }

  Future<List<Widget>> pumpLayouts(
    WidgetTester tester,
    NaturalBlockBuilders builders,
    List<LayoutNode> nodes,
  ) => buildWith(tester, builders, (scope) => buildLayouts(nodes, scope));

  TextNode text(String s) => TextNode(children: [TextSpanNode(text: s)]);

  group('NaturalBlockBuilders.defaults', () {
    testWidgets(
      'one RowNode renders as one Row, keeping other blocks separate',
      (tester) async {
        final built = await pumpLayouts(tester, NaturalBlockBuilders.defaults, [
          RowNode(
            children: [
              ColumnNode(children: [text('a')]),
              ColumnNode(children: [text('b')]),
            ],
          ),
          ColumnNode(children: [text('between')]),
          RowNode(
            children: [
              ColumnNode(children: [text('c')]),
              ColumnNode(children: [text('d')]),
            ],
          ),
        ]);

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

  group('builders of your own', () {
    testWidgets(
      'a ColumnNode builder also applies to row cells, since cells are '
      'built through the builders',
      (tester) async {
        final builders = NaturalBlockBuilders(
          column: (node, scope) => const Placeholder(),
        );

        await pumpLayouts(tester, builders, [
          RowNode(
            children: [
              ColumnNode(children: [text('a')]),
              ColumnNode(children: [text('b')]),
            ],
          ),
        ]);

        expect(find.byType(Placeholder), findsNWidgets(2));
        expect(find.byType(TextNodeView), findsNothing);
      },
    );
  });
}
