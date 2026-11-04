// Draws doc/showcase.png, the picture in the README. Not a test: it reads
// Windows' own fonts, which are not ours to ship, so it runs only on Windows.
//
//   flutter test tool/showcase.dart --update-goldens
//
// When _source changes, paste it into both READMEs too.
@TestOn('windows')
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

const _source = '''
:++*%natural_block:: sample

Ordinary prose passes through. C++, 100%, Really?! and you@example.com are untouched.

:!Danger:! and :%Success:% and :*Emphasis:*

Alignment starts a line with `<` `=` `>`; a row starts a line with `^` and closes with `^`.

`
final x = a == b ? 1 : 2;
cat file.txt | grep foo | wc -l
`

A table is wrapped in `~`. Columns fit their content.

~
:*Item::^>:*Price::^=:*Stock::^
Apple^150^12^
Banana^98^3^
Grape^1280^1^
~

:-A region on its own lines becomes a box; one inside a line becomes monospace text.

^Updated^^>2026-09-02^
''';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    loader.addFont(
      File('C:/Windows/Fonts/$file').readAsBytes().then(ByteData.sublistView),
    );
  }
  await loader.load();
}

void main() {
  setUpAll(() async {
    await _loadFont('Segoe UI', ['segoeui.ttf', 'segoeuib.ttf']);
    await _loadFont('monospace', ['consola.ttf']);
  });

  testWidgets('showcase', (tester) async {
    tester.view.physicalSize = const Size(760, 1180);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          fontFamily: 'Segoe UI',
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: NaturalBlockView(
                  source: _source,
                  theme: NaturalBlockTheme.fromContext(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../doc/showcase.png'),
    );
  });
}
