import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

// Drawn in fonts kept beside this file, so the pictures can be read. Another
// OS may smooth the glyphs differently by a pixel or so; if these ever run
// elsewhere, compare with a small tolerance rather than give the fonts up.
// A failure leaves the old image, the new one and their difference under
// `failures/`.
//
// Regenerate with:
//   flutter test test/golden --update-goldens

final _scheme = ColorScheme.fromSeed(seedColor: Colors.deepPurple);

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    loader.addFont(
      File('test/golden/fonts/$file').readAsBytes().then(ByteData.sublistView),
    );
  }
  await loader.load();
}

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
      theme: ThemeData(colorScheme: _scheme, fontFamily: 'Roboto'),
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
                  spacing: 8,
                  children: [
                    for (final (source, theme) in samples)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black26),
                        ),
                        child: NaturalBlockView(source: source, theme: theme),
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
  setUpAll(() async {
    await _loadFont('Roboto', ['Roboto-Regular.ttf', 'Roboto-Bold.ttf']);
    await _loadFont('monospace', ['RobotoMono-Regular.ttf']);
  });

  testWidgets('block alignment', (tester) async {
    await _scene(tester, 'alignment', [
      ('unstated', null),
      ('<start', null),
      ('=center', null),
      ('>end', null),
      ('>a line, then a raw block\n`\nx\n`', null),
      ('=a centred paragraph long enough to wrap onto a second line', null),
      ('=intro\n`\nif (x) {\n    y();\n}\n`', null),
    ]);
  });

  testWidgets('rows', (tester) async {
    await _scene(tester, 'rows', [
      ('^Apple^200^1000^\n^Banana^1^2^', null),
      ('^a\nb\nc^d^', null),
      ('^a^^c^', null),
      ('^<left^>right^', null),
      ('^<a^=b^>c^', null),
      ('^=a^bb^ccc^', null),
      ('^=a centred cell long enough to wrap onto a second line^>end^', null),
    ]);
  });

  testWidgets('tables', (tester) async {
    await _scene(tester, 'tables', [
      ('~Item^Price^\nApple^200^\nBanana^1^~', null),
      ('~\nA^>BBBB^\nC^D^\nE^<F^\n~', null),
      ('~a^b^\nc^~', null),
      ('~one cell~', null),
      ('=~A^B~', null),
      (
        '~a^b^\nc^d^\ne^f^~',
        NaturalBlockTheme.fromColorScheme(_scheme, striped: true),
      ),
      ('~a^b^\nc^d^~', const NaturalBlockTheme(tableBorder: TableBorder())),
      (
        '~a^b^\nc^d^~',
        const NaturalBlockTheme(
          tableCellPadding: EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
    ]);
  });

  testWidgets('raw regions', (tester) async {
    final long = '`\n${'word ' * 30}\n`';
    await _scene(tester, 'raw', [
      ('`\nif (x) {\n    y();\n}\n`', null),
      ('inline `a ^^ b` run', null),
      (long, null),
      (long, const NaturalBlockTheme(rawScrollsHorizontally: true)),
      ('`\nno box\n`', const NaturalBlockTheme(rawDecoration: BoxDecoration())),
      ('`\nx\n`', const NaturalBlockTheme(base: TextStyle(fontSize: 24))),
      ('`\nx\n`', const NaturalBlockTheme(raw: TextStyle(fontSize: 24))),
    ]);
  });

  testWidgets('decorations and themes', (tester) async {
    const marks = ':!neg:! :%pos:% :*em:* :@custom:@ plain';
    await _scene(tester, 'decorations', [
      (marks, null),
      (marks, const NaturalBlockTheme()),
      ('<:+one\n<:++two\n<:-down', null),
      (':!*+marked:!*+plain', null),
      (
        ':!toned:! plain :+bigger',
        const NaturalBlockTheme(base: TextStyle(fontSize: 24)),
      ),
    ]);
  });

  testWidgets('everything nested in one document', (tester) async {
    await _scene(tester, 'combined', [
      (
        '=:++:*Combined::\n'
            '^<:!left:!^=centre `raw`^>:%right:%^\n'
            '~\n'
            '=:*Item::^>:*Price::^\n'
            ':@apple:@^>200^\n'
            '`banana`^>1^\n'
            '~\n'
            '^a cell beside a table^~x^y^\nz^w^~^\n'
            '=~A^B~\n'
            '^intro\n'
            '`\n'
            'if (x) {\n'
            '    y();\n'
            '}\n'
            '`^>:-side note^',
        null,
      ),
    ]);
  });
}
