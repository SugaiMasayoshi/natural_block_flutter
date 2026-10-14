import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

// Drawn in the test font, whose glyphs are plain boxes, so positions and
// sizes come out the same on any machine. A failure leaves the old image,
// the new one and their difference under `failures/`.
//
// Regenerate with:
//   flutter test test/golden --update-goldens

final _scheme = ColorScheme.fromSeed(seedColor: Colors.deepPurple);

/// One sample: a source, and the theme to draw it with when not the
/// ambient one.
typedef _Sample = (String source, NaturalBlockTheme? theme);

Future<void> _scene(
  WidgetTester tester,
  String name,
  List<_Sample> samples,
) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: _scheme),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: const Key('scene'),
            child: ColoredBox(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final (source, theme) in samples)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black26),
                          ),
                          child: NaturalBlockView(source: source, theme: theme),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await expectLater(
    find.byKey(const Key('scene')),
    matchesGoldenFile('goldens/$name.png'),
  );
}

void main() {
  testWidgets('block alignment', (tester) async {
    await _scene(tester, 'alignment', [
      ('unstated', null),
      ('|<start', null),
      ('|=center', null),
      ('|>end', null),
      ('|>a line, then a raw block\n`\nx\n`', null),
      ('|=a centred paragraph long enough to wrap onto a second line', null),
      ('|=intro\n`\nif (x) {\n    y();\n}\n`', null),
    ]);
  });

  testWidgets('rows', (tester) async {
    await _scene(tester, 'rows', [
      ('Apple^200^1000|Banana^1^2', null),
      ('a\nb\nc^d', null),
      ('a^^c', null),
      ('|<left^>right', null),
      ('|<a^=b^>c', null),
      ('|=a^bb^ccc', null),
      ('|=centred cells that wrap^>end', null),
    ]);
  });

  testWidgets('tables', (tester) async {
    await _scene(tester, 'tables', [
      ('~Item^Price|Apple^200|Banana^1~', null),
      ('~|A^>B\n|C^DDDD\n~', null),
      ('~a^b|c~', null),
      ('|=~A^B~', null),
      (
        '~a^b|c^d|e^f~',
        NaturalBlockTheme.fromColorScheme(_scheme, striped: true),
      ),
      ('~a^b|c^d~', const NaturalBlockTheme(tableBorder: TableBorder())),
      (
        '~a^b|c^d~',
        const NaturalBlockTheme(
          tableCellPadding: EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
    ]);
  });

  testWidgets('raw regions', (tester) async {
    final long = '`${'word ' * 30}`';
    await _scene(tester, 'raw', [
      ('`\nif (x) {\n    y();\n}\n`', null),
      ('inline `a ^^ b` run', null),
      (long, null),
      (long, const NaturalBlockTheme(rawScrollsHorizontally: true)),
      ('`no box`', const NaturalBlockTheme(rawDecoration: BoxDecoration())),
      ('`x`', const NaturalBlockTheme(base: TextStyle(fontSize: 24))),
    ]);
  });

  testWidgets('decorations and themes', (tester) async {
    const marks = ':!neg:! :%pos:% :*em:* :@custom:@ plain';
    await _scene(tester, 'decorations', [
      (marks, null),
      (marks, const NaturalBlockTheme()),
      (':+one|:++two|:-down', null),
      (':!*+marked:!*+plain', null),
      (
        ':+bigger plain',
        const NaturalBlockTheme(base: TextStyle(fontSize: 24)),
      ),
    ]);
  });

  testWidgets('everything nested in one document', (tester) async {
    await _scene(tester, 'combined', [
      (
        '|=:++:*Combined::\n'
            '|<:!left:!^=centre `raw`^>:%right:%\n'
            '|\n'
            '~|=:*Item::^>:*Price::\n'
            '|:@apple:@^>200\n'
            '|`banana`^>1\n'
            '~\n'
            '|a cell beside a table^~x^y|z^w~\n'
            '|=~A^B~\n'
            '|intro\n'
            '`\n'
            'if (x) {\n'
            '    y();\n'
            '}\n'
            '`^>:-side note',
        null,
      ),
    ]);
  });
}
