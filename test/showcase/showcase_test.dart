// 【解説】読む順番 9/9：見本画像を作るだけで、振る舞いは守らない。最後に。
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

// 【解説】見本画像に描く文書。`'''…'''` は複数行の文字列。記法のほぼ全部（大きさ・色・強調・
// 【解説】行・raw・表・寄せ）を1枚に入れている。
const _source = '''
:++:*:%natural_block:: 見本

普通の文章はそのまま通ります。C++ も 100% も Really?! も you@example.com も無傷です。

:!危険:! と :%成功:% と :*強調:*

区切りは `|` で、横並びは `^` です。どちらも区間の中では効きません。

`
final x = a == b ? 1 : 2;
cat file.txt | grep foo | wc -l
`

表は `~` で宣言します。列幅は内容に揃います。

~
|:*商品::^>:*価格::^=:*在庫::
|りんご^150^12
|バナナ^98^3
|ぶどう^1280^1
~

:-単独の区間は枠になり、文中の区間は等幅の文字になります。

|更新日^^>2026-09-02|
''';

// 【解説】テストでは標準のフォントが使えない（文字が四角になる）ので、Windows のフォントファイルを
// 【解説】読み込んで名前を付けて登録する。`..addFont` は「loader に対して addFont を呼ぶ」書き方
// 【解説】（cascade）。ファイルを読んだ bytes を ByteData に変えて渡している。
Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader(family)
    ..addFont(File(path).readAsBytes().then((b) => b.buffer.asByteData()));
  await loader.load();
}

// 【解説】使うフォントの場所（日本語：游ゴシック、等幅：Consolas）。
const _japanese = r'C:\Windows\Fonts\YuGothR.ttc';
const _mono = r'C:\Windows\Fonts\consola.ttf';

void main() {
  // 【解説】このファイルのテストの前に1回だけ、フォントを読み込む。
  setUpAll(() async {
    if (!_fontsAvailable) return;
    await _loadFont('YuGothic', _japanese);
    await _loadFont('monospace', _mono);
  });

  // Regenerate with:
  //   flutter test test/showcase --update-goldens
  // 【解説】振る舞いを守るテストではなく、見本の画像を作って見比べるためのもの。
  // 【解説】画面の大きさと倍率を決めて描き、保存してある showcase.png と1画素ずつ比べる（golden テスト）。
  // 【解説】フォントがある Windows でだけ動き、それ以外では最後の `skip:` で飛ばされる。
  // 【解説】`addTearDown(tester.view.reset)` で、変えた画面の大きさをテスト後に戻す。
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
    // 【解説】動きが止まるまで描画を進める（画像の読み込みなどを待つ）。
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('showcase.png'),
    );
  }, skip: !_fontsAvailable);
}

// 【解説】Windows で、2つのフォントファイルが両方あるときだけ true。
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
