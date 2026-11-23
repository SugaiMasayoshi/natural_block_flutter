import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

void main() {
  Future<List<RenderBox>> cellsOf(WidgetTester tester, String source) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: NaturalBlockView(source: source),
        ),
      ),
    );
    return tester
        .renderObjectList<RenderBox>(find.byType(TextNodeView))
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
    final [tall, _, _, short] = await cellsOf(tester, '^a\nb\nc^d^');

    expect(top(short), top(tall));
  });

  testWidgets('an aligned cell still lines up on the baseline', (tester) async {
    final [tall, _, _, short] = await cellsOf(tester, '=^:++A\nb\nc^d^');

    expect(baseline(short), baseline(tall));
  });

  testWidgets('the first line of a tall cell is the one that lines up', (
    tester,
  ) async {
    final [tall, _, _, small] = await cellsOf(tester, '^:++A\nb\nc^d^');

    expect(baseline(small), baseline(tall));
  });
}
