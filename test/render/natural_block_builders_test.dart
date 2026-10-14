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
  });

  group('cells are built through the builders', () {
    Future<void> pump(
      WidgetTester tester,
      String source,
      NaturalBlockBuilders builders,
    ) => tester.pumpWidget(
      MaterialApp(
        home: NaturalBlockView(source: source, builders: builders),
      ),
    );

    testWidgets('a row cell is a column', (tester) async {
      await pump(
        tester,
        'a^b',
        NaturalBlockBuilders(column: (node, scope) => const Placeholder()),
      );

      expect(find.byType(Placeholder), findsNWidgets(2));
      expect(find.byType(TextNodeView), findsNothing);
    });

    testWidgets('a table cell is a tableCell', (tester) async {
      await pump(
        tester,
        '~a^b~',
        NaturalBlockBuilders(tableCell: (node, scope) => const Placeholder()),
      );

      expect(find.byType(Placeholder), findsNWidgets(2));
      expect(find.byType(TextNodeView), findsNothing);
    });
  });
}
