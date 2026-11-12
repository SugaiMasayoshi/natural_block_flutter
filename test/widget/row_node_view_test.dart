import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
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

  testWidgets('cells of different sizes sit on one baseline', (tester) async {
    final [large, small, larger] = await cellsOf(tester, '^:++A^B^:+++C^');

    expect(baseline(small), baseline(large));
    expect(baseline(larger), baseline(large));
    expect(top(small), greaterThan(top(larger)));
  });

  testWidgets('cells whose first lines match start at the same height', (
    tester,
  ) async {
    final [tall, short] = await cellsOf(tester, '^a\nb\nc^d^');

    expect(top(short), top(tall));
  });

  testWidgets('the first line of a tall cell is the one that lines up', (
    tester,
  ) async {
    final [tall, small] = await cellsOf(tester, '^:++A\nb\nc^d^');

    expect(baseline(small), baseline(tall));
  });
}
