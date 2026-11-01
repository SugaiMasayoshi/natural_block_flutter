import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

const _source = '''
:++:*:%natural_block:: 見本

普通の文章はそのまま通ります。C++ も 100% も Really?! も you@example.com も無傷です。

:!危険:! と :%成功:% と :*強調:*

寄せは行頭の `<` `=` `>` で、横並びは行頭の `^` で始めて `^` で閉じます。

`
final x = a == b ? 1 : 2;
cat file.txt | grep foo | wc -l
`

表は `~` で宣言します。列幅は内容に揃います。

~
:*商品::^>:*価格::^=:*在庫::
りんご^150^12
バナナ^98^3
ぶどう^1280^1
~

:-単独の区間は枠になり、文中の区間は等幅の文字になります。

^更新日^^>2026-09-02^
''';

Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(File(path).readAsBytes().then((b) => b.buffer.asByteData()));
  await loader.load();
}

const _japanese = r'C:\Windows\Fonts\YuGothR.ttc';
const _mono = r'C:\Windows\Fonts\consola.ttf';

void main() {
  setUpAll(() async {
    if (!_fontsAvailable) return;
    await _loadFont('YuGothic', _japanese);
    await _loadFont('monospace', _mono);
  });

  // Regenerate with:
  //   flutter test test/showcase --update-goldens
  testWidgets('showcase', (tester) async {
    tester.view.physicalSize = const Size(760, 1180);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          fontFamily: 'YuGothic',
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
      matchesGoldenFile('showcase.png'),
    );
  }, skip: !_fontsAvailable);
}

/// Whether this machine has the fonts the picture was drawn with.
///
/// The test runs only where it does, and is skipped everywhere else: golden
/// comparison is pixel-exact and these paths are Windows-only, so it can only
/// pass on a machine set up like the one that produced the image. Its job is
/// to produce something to look at, not to guard behaviour -- every other
/// test in this package does that.
final bool _fontsAvailable =
    Platform.isWindows &&
    File(_japanese).existsSync() &&
    File(_mono).existsSync();
