import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

void main() {
  group('ColumnNodeView', () {
    testWidgets('stacks its children vertically in a Column', (tester) async {
      const children = [Text('first'), Text('second')];

      await tester.pumpWidget(
        const MaterialApp(home: ColumnNodeView(children: children)),
      );

      final column = tester.widget<Column>(find.byType(Column));
      expect(column.children, hasLength(2));
      expect(column.crossAxisAlignment, CrossAxisAlignment.start);
      expect(column.mainAxisSize, MainAxisSize.min);
      expect(find.text('first'), findsOneWidget);
      expect(find.text('second'), findsOneWidget);
    });

    testWidgets('renders an empty Column for an empty children list', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: ColumnNodeView(children: [])),
      );

      final column = tester.widget<Column>(find.byType(Column));
      expect(column.children, isEmpty);
      expect(tester.takeException(), isNull);
    });

    for (final entry in {
      HorizontalAlign.start: CrossAxisAlignment.start,
      HorizontalAlign.center: CrossAxisAlignment.center,
      HorizontalAlign.end: CrossAxisAlignment.end,
    }.entries) {
      testWidgets(
        'align: ${entry.key} maps to crossAxisAlignment: ${entry.value}',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: ColumnNodeView(
                align: entry.key,
                children: const [Text('only')],
              ),
            ),
          );

          final column = tester.widget<Column>(find.byType(Column));
          expect(column.crossAxisAlignment, entry.value);
        },
      );
    }
  });
}
