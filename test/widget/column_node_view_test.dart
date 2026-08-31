import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
  });
}
