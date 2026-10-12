import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

void main() {
  group('ColumnNodeView', () {
    for (final entry in {
      HorizontalAlign.start: 0.0,
      HorizontalAlign.center: 40.0,
      HorizontalAlign.end: 80.0,
    }.entries) {
      testWidgets('${entry.key} places a narrow child within a wide one', (
        tester,
      ) async {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: ColumnNodeView(
              align: entry.key,
              children: const [
                SizedBox(key: Key('wide'), width: 100, height: 10),
                SizedBox(key: Key('narrow'), width: 20, height: 10),
              ],
            ),
          ),
        );

        expect(
          tester.getTopLeft(find.byKey(const Key('narrow'))).dx -
              tester.getTopLeft(find.byKey(const Key('wide'))).dx,
          entry.value,
        );
      });
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
  });
}
