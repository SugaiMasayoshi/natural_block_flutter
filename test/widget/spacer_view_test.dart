import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

const _theme = NaturalBlockTheme(base: TextStyle(fontSize: 20));

void main() {
  Future<void> pumpIn(
    WidgetTester tester,
    String source, {
    double? height,
    TextDirection direction = TextDirection.ltr,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 400,
            height: height,
            child: NaturalBlockView(source: source, theme: _theme),
          ),
        ),
      ),
    ),
  );

  Rect rectOf(WidgetTester tester, String text) => tester.getRect(
    find
        .ancestor(
          of: find.textContaining(text, findRichText: true).first,
          matching: find.byType(ColumnNodeView),
        )
        .first,
  );

  testWidgets('spacers above and below put a block in the middle', (
    tester,
  ) async {
    await pumpIn(tester, '|\n=Title\n|', height: 300);

    final title = rectOf(tester, 'Title');
    expect(title.top, closeTo(300 - title.bottom, 0.01));
  });

  testWidgets('a spacer of two takes twice the share of one', (tester) async {
    await pumpIn(tester, '||\nTitle\n|', height: 300);

    final title = rectOf(tester, 'Title');
    expect(title.top, closeTo(2 * (300 - title.bottom), 0.01));
  });

  testWidgets('a spacer pushes what follows to the bottom', (tester) async {
    await pumpIn(tester, 'Body\n|\nSource', height: 300);

    expect(rectOf(tester, 'Body').top, 0);
    expect(rectOf(tester, 'Source').bottom, closeTo(300, 0.01));
  });

  testWidgets('where the height is not set, a spacer takes none', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SingleChildScrollView(
          child: NaturalBlockView(source: 'A\n|\nB', theme: _theme),
        ),
      ),
    );

    expect(rectOf(tester, 'B').top, rectOf(tester, 'A').bottom);
  });

  testWidgets('where the height is not set, what fills a spacer still shows', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SingleChildScrollView(
          child: NaturalBlockView(
            source: 'A\n|\nB',
            theme: _theme,
            // ignore: non_const_argument_for_const_parameter
            builders: NaturalBlockBuilders(
              spacer: (node, scope) => SpacerNodeView(
                flex: node.flex,
                child: const SizedBox(height: 40),
              ),
            ),
          ),
        ),
      ),
    );

    expect(rectOf(tester, 'B').top - rectOf(tester, 'A').bottom, 40);
  });

  testWidgets('a cell with spacers places its content in the row height', (
    tester,
  ) async {
    await pumpIn(tester, '^Tall\nTall\nTall\nTall^|\nMiddle\n|^');

    final tall = rectOf(tester, 'Tall');
    final middle = rectOf(tester, 'Middle');
    expect(middle.center.dy, closeTo(tall.center.dy, 0.01));
  });

  testWidgets('a cell with a spacer on top sits at the bottom of the row', (
    tester,
  ) async {
    await pumpIn(tester, '^Tall\nTall\nTall^|\nLow^');

    final tall = rectOf(tester, 'Tall');
    expect(rectOf(tester, 'Low').bottom, closeTo(tall.bottom, 0.01));
  });

  testWidgets('cells keep their order right to left', (tester) async {
    await pumpIn(
      tester,
      '^First\nFirst^|\nSecond^',
      direction: TextDirection.rtl,
    );

    expect(
      rectOf(tester, 'Second').left,
      lessThan(rectOf(tester, 'First').left),
    );
  });

  testWidgets('cells without spacers still share a baseline', (tester) async {
    await pumpIn(tester, '^:++A^B^|\nC\n|^');

    final [large, small, _] = tester
        .renderObjectList<RenderParagraph>(find.byType(RichText))
        .toList();
    double baseline(RenderBox box) =>
        box.localToGlobal(Offset.zero).dy +
        box.getDryBaseline(box.constraints, TextBaseline.alphabetic)!;
    expect(baseline(small), baseline(large));
  });
}
