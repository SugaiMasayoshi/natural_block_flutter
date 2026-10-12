import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

void main() {
  group('RowNodeView', () {
    testWidgets('gives every cell one Expanded, empty ones included', (
      tester,
    ) async {
      // An empty cell still takes its share of the width, which is what
      // keeps later columns lined up between rows.
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
      // A Row cannot lay out flex children when its own width is unbounded,
      // so wrapping every cell in Expanded unconditionally made any document
      // containing `^` throw inside a horizontal scroll view.
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
    // Measures real cell geometry rather than widget properties, so these
    // prove where the cells actually landed.
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
        // The reason RowNodeView uses Expanded at all: a RowNodeView cannot
        // see sibling rows, so equal fractions of a known width are the only
        // thing that makes consecutive rows share column positions.
        await tester.pumpWidget(
          const MaterialApp(
            home: NaturalBlockView(source: 'Apple^200^1000|Banana^1^2'),
          ),
        );

        // Asserted as a relationship rather than in absolute pixels: the
        // point is that the columns agree between rows and are evenly
        // spaced, whatever width the surface happens to be.
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
      // Regression: cells were wrapped in Expanded unconditionally, and a
      // Row cannot lay out flex children when its own width is unbounded
      // -- so any document containing "^" threw inside a horizontal
      // scroll view, i.e. stopped rendering entirely.
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

      // Cells are packed at their own content width, in order.
      expect(left(tester, 'Apple'), 0);
      expect(left(tester, '200'), greaterThan(0));
      expect(left(tester, '1000'), greaterThan(left(tester, '200')));
    });

    testWidgets('a row nested in another Row renders without throwing', (
      tester,
    ) async {
      // The other unbounded case: a parent Row gives its children unbounded
      // width on the main axis just as a horizontal scroll view does.
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
        // Documents the accepted cost rather than asserting the fallback is
        // equivalent. With no width to divide there is nothing to keep the
        // rows in step, so a table stops reading as a table -- accepted
        // only because the alternative is not rendering at all.
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
}
