// 【解説】[テスト21/21] 見本。テストではなく「見るもの」を作る唯一の場所。
// 【解説】
// 【解説】 通常のテスト実行から外してある。Windows のフォントパスを直書きし、
// 【解説】 画素単位で比較するので、生成した機械以外では必ず落ちるため。
// 【解説】 挙動を守るのは他の134テストの仕事で、これの役目は画像を作ること。
// 【解説】
// 【解説】 作る価値はあった。最初の描画で、見本のソース自体の間違いが
// 【解説】 見つかっている。行の前に | を置いていなかったので直前の行が
// 【解説】 最初のセルに吸収されていた。パースは成功し例外も出ないので、
// 【解説】 画像を見なければ気づけなかった。この規則は今 README にある。
// 【解説】
// 【解説】 描き直す: flutter test test/showcase --update-goldens
// 【解説】 これで最後。lib 側は [1/21] から読める。

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

const _source = '''
:++:*:?natural_block:: 見本

普通の文章はそのまま通ります。C++ も 100% も Really?! も you@example.com も無傷です。

:!危険:! と :%成功:% と :?情報:? と :*強調:*

区切りは `|` で、横並びは `=` です。どちらも区間の中では効きません。

`
final x = a == b ? 1 : 2;
cat file.txt | grep foo | wc -l
`

表は `|~` で宣言します。列幅は内容に揃います。

|~:*商品::=>:*価格::=^:*在庫::|
りんご=150=12|
バナナ=98=3|
ぶどう=1280=1|~

:-単独の区間は枠になり、文中の区間は等幅の文字になります。

|更新日==>2026-09-02|
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

  // Skipped in the normal suite on purpose: it loads fonts from a hardcoded
  // Windows path and compares against a golden, so it can only pass on the
  // machine that generated it. Its job is to produce a picture to look at,
  // not to guard behaviour -- that is what the other tests are for.
  //
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
/// Skipped everywhere else on purpose. Golden comparison is pixel-exact and
/// these paths are Windows-only, so this test can only pass on the machine
/// that produced the image -- its job is to produce something to look at,
/// not to guard behaviour. Every other test in this package does that.
final bool _fontsAvailable =
    Platform.isWindows &&
    File(_japanese).existsSync() &&
    File(_mono).existsSync();
