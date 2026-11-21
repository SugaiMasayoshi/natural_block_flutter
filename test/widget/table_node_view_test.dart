import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

void main() {
  Future<List<RenderParagraph>> cellsOf(
    WidgetTester tester,
    String source,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: NaturalBlockView(source: source),
        ),
      ),
    );
    return tester
        .renderObjectList<RenderParagraph>(find.byType(RichText))
        .toList();
  }

  double top(RenderBox box) => box.localToGlobal(Offset.zero).dy;

  double baseline(RenderBox box) =>
      top(box) + box.getDryBaseline(box.constraints, TextBaseline.alphabetic)!;

  testWidgets('cells of different sizes sit on one baseline, as in a row', (
    tester,
  ) async {
    final [large, small, larger] = await cellsOf(tester, '~\n:++A^B^:+++C^\n~');

    expect(baseline(small), baseline(large));
    expect(baseline(larger), baseline(large));
    expect(top(small), greaterThan(top(larger)));
  });

  testWidgets('a cell of several lines lines up on its first', (tester) async {
    final [tall, short] = await cellsOf(tester, '~\n:++A\nb\nc^d^\n~');

    expect(baseline(short), baseline(tall));
  });
}
