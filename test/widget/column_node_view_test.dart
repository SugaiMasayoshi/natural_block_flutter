import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

    for (final entry in {
      HorizontalAlign.unstated: TextAlign.start,
      HorizontalAlign.start: TextAlign.start,
      HorizontalAlign.center: TextAlign.center,
      HorizontalAlign.end: TextAlign.end,
    }.entries) {
      testWidgets('${entry.key} aligns the lines of a wrapped paragraph', (
        tester,
      ) async {
        late BuildContext inside;
        await tester.pumpWidget(
          MaterialApp(
            home: ColumnNodeView(
              align: entry.key,
              children: [
                Builder(
                  builder: (context) {
                    inside = context;
                    return const SizedBox();
                  },
                ),
              ],
            ),
          ),
        );

        expect(DefaultTextStyle.of(inside).textAlign, entry.value);
      });
    }
  });

  group('block alignment (end-to-end)', () {
    Future<void> pumpWide(WidgetTester tester, String source) =>
        tester.pumpWidget(
          MaterialApp(
            home: SizedBox(width: 800, child: NaturalBlockView(source: source)),
          ),
        );

    Rect glyphRect(WidgetTester tester, RichText richText) {
      final renderParagraph = tester.renderObject<RenderParagraph>(
        find.byWidget(richText),
      );
      final boxes = renderParagraph.getBoxesForSelection(
        TextSelection(
          baseOffset: 0,
          extentOffset: renderParagraph.text.toPlainText().length,
        ),
      );
      final box = boxes.single;
      final topLeft = renderParagraph.localToGlobal(Offset(box.left, box.top));
      final bottomRight = renderParagraph.localToGlobal(
        Offset(box.right, box.bottom),
      );
      return Rect.fromPoints(topLeft, bottomRight);
    }

    testWidgets('|<A^>B| aligns A to the left and B to the right', (
      tester,
    ) async {
      await pumpWide(tester, '|<A^>B|');

      final richTexts = tester
          .widgetList<RichText>(find.byType(RichText))
          .toList();
      expect(richTexts, hasLength(2));

      final aRect = glyphRect(tester, richTexts[0]);
      final bRect = glyphRect(tester, richTexts[1]);

      expect(aRect.left, closeTo(0, 1));
      expect(bRect.right, closeTo(800, 1));
    });

    testWidgets('|=A| centers the block', (tester) async {
      await pumpWide(tester, '|=A|');

      final richText = tester.widget<RichText>(find.byType(RichText));
      final rect = glyphRect(tester, richText);
      final center = (rect.left + rect.right) / 2;

      expect(center, closeTo(400, 1));
    });

    testWidgets('a source with no alignment markers is unchanged', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: NaturalBlockView(source: 'left|right')),
      );

      final columns = tester.widgetList<Column>(find.byType(Column));
      expect(columns, isNotEmpty);
      for (final column in columns) {
        expect(column.crossAxisAlignment, CrossAxisAlignment.start);
      }
    });
  });

  group('block alignment in an unbounded width', () {
    for (final source in ['|=A|', '|>A|']) {
      testWidgets(
        '"$source" renders inside a horizontal scroll view without throwing',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: NaturalBlockView(source: source),
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull);
          expect(find.byType(RichText), findsOneWidget);
        },
      );
    }
  });
}
