import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

void main() {
  group('RowNodeView', () {
    testWidgets('gives every cell one Expanded, empty ones included', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RowNodeView(cells: [Text('a'), SizedBox.shrink(), Text('c')]),
        ),
      );

      expect(find.byType(Row), findsOneWidget);
      expect(find.byType(Expanded), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('shrink-wraps its cells where the width is unbounded', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: RowNodeView(cells: [Text('a'), Text('b')]),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(Expanded), findsNothing);
    });
  });

  group('row cell widths', () {
    double left(WidgetTester tester, String text) => tester
        .getTopLeft(
          find.byWidget(
            tester
                .widgetList<RichText>(find.byType(RichText))
                .firstWhere((w) => w.text.toPlainText() == text),
          ),
        )
        .dx;

    testWidgets(
      'cells split a bounded width equally, so columns line up across rows',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: NaturalBlockView(source: 'Apple^200^1000|Banana^1^2'),
          ),
        );

        final width = tester.getSize(find.byType(NaturalBlockView)).width;
        final third = width / 3;

        for (final row in [
          ['Apple', '200', '1000'],
          ['Banana', '1', '2'],
        ]) {
          expect(left(tester, row[0]), closeTo(0, 0.01));
          expect(left(tester, row[1]), closeTo(third, 0.01));
          expect(left(tester, row[2]), closeTo(2 * third, 0.01));
        }
      },
    );

    testWidgets('a row in an unbounded width shrink-wraps its cells instead of '
        'throwing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: NaturalBlockView(source: 'Apple^200^1000'),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(RichText), findsNWidgets(3));

      expect(left(tester, 'Apple'), 0);
      expect(left(tester, '200'), greaterThan(0));
      expect(left(tester, '1000'), greaterThan(left(tester, '200')));
    });

    testWidgets('a row nested in another Row renders without throwing', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Row(children: [NaturalBlockView(source: 'a^b')]),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(RichText), findsNWidgets(2));
    });

    testWidgets(
      'the unbounded fallback is a degradation: columns stop lining up '
      'across rows',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: NaturalBlockView(source: 'Apple^200|Banana^1'),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(
          left(tester, '200'),
          isNot(closeTo(left(tester, '1'), 0.01)),
          reason:
              'the second column of each row does not align when '
              'cells shrink-wrap',
        );
      },
    );
  });

  group('row cell heights', () {
    testWidgets('cells of different heights share a top edge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: NaturalBlockView(source: 'a\nb\nc^d')),
      );

      double top(String text) => tester
          .getTopLeft(
            find.byWidget(
              tester
                  .widgetList<RichText>(find.byType(RichText))
                  .firstWhere((w) => w.text.toPlainText().startsWith(text)),
            ),
          )
          .dy;

      expect(top('d'), top('a'));
    });
  });
}
