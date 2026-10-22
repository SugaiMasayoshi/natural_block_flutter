// 【解説】読む順番 2/9：見た目の全体像。寄せ・行・表・raw・装飾の描かれ方を画像で守る。画像も一緒に見る。
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

// 【解説】全部の画像で使う色の組。テーマを渡さない見本は、ここから作られた色で描かれる。
final _scheme = ColorScheme.fromSeed(seedColor: Colors.deepPurple);

// 【解説】fonts/ に置いたフォントのファイルを読み込み、family の名前で使えるようにする補助。
// 【解説】テストは普通、字がすべて箱のテスト用フォントで描かれる。読める字で描くために自分で読み込む。
// 【解説】`ByteData.sublistView` は読み込んだバイト列を FontLoader が受け取る形に包み直す。
Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    loader.addFont(
      File('test/golden/fonts/$file').readAsBytes().then(ByteData.sublistView),
    );
  }
  await loader.load();
}

// 【解説】見本1つ＝（記法の文字列, テーマ）の組（レコード）。テーマが null なら周りのテーマを使う。
/// One sample: a source, and the theme to draw it with when not the
/// ambient one.
typedef _Sample = (String source, NaturalBlockTheme? theme);

// 【解説】見本を枠付きで縦に並べて描き、goldens/<name>.png と1画素ずつ比べる補助。
// 【解説】各テストは「どの見本を並べるか」だけを書けばよい。
Future<void> _scene(
  WidgetTester tester,
  String name,
  List<_Sample> samples,
) async {
  // 【解説】画面を幅400・高さ800、1論理ピクセル＝1画素に固定する。機械によって画像が変わらないように。
  // 【解説】`addTearDown(tester.view.reset)` で、テストが終わったら元の画面設定に戻す。
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
            // 【解説】RepaintBoundary の中だけが画像になる。Key はそれを find で見つけるための目印。
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
                    // 【解説】`(source, theme)` はレコードの分解。見本の2つの値をそれぞれの名前で受け取る。
                    // 【解説】DecoratedBox の灰色の枠は見本の境目で、寄せが枠のどこに着くかを見るためのもの。
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
    // 【解説】保存済みの画像と比べる。違えば失敗し、failures/ に旧・新・差分の画像が残る。
    matchesGoldenFile('goldens/$name.png'),
  );
}

void main() {
  // 【解説】全部のテストの前に1回だけ、Roboto（普通と太字）と、raw 用の等幅フォントを読み込む。
  // 【解説】等幅は 'monospace' の名前で読み込むので、テーマの raw の既定（fontFamily: 'monospace'）がそのまま使う。
  setUpAll(() async {
    await _loadFont('Roboto', ['Roboto-Regular.ttf', 'Roboto-Bold.ttf']);
    await _loadFont('monospace', ['RobotoMono-Regular.ttf']);
  });

  // 【解説】ブロックの寄せ。寄せなし・左・中央・右、折り返した段落、行と raw が別々の子になる場合
  // 【解説】（右寄せの行と raw の箱がどちらも右端に着く）、中央寄せの中の raw（箱は中央、中身は左揃え）。
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

  // 【解説】`^` の行。セルが幅を等分すること、複数行のセル、空のセル、セルごとの寄せ。
  // 【解説】`|=a^bb^ccc` は寄せの記号が最初のセルにしか効かないことを示す。
  testWidgets('rows', (tester) async {
    await _scene(tester, 'rows', [
      ('Apple^200^1000|Banana^1^2', null),
      ('a\nb\nc^d', null),
      ('a^^c', null),
      ('|<left^>right', null),
      ('|<a^=b^>c', null),
      ('|=a^bb^ccc', null),
      ('|=a centred cell long enough to wrap onto a second line^>end', null),
    ]);
  });

  // 【解説】`~` の表。列が中身に合うこと、列の寄せの引き継ぎ（D）とセル自身の寄せが勝つこと（F）、短い行の埋め方、中央に置いた表、
  // 【解説】縞・枠線なし・セルの余白のテーマ。
  testWidgets('tables', (tester) async {
    await _scene(tester, 'tables', [
      ('~Item^Price|Apple^200|Banana^1~', null),
      ('~|A^>BBBB\n|C^D\n|E^<F\n~', null),
      ('~a^b|c~', null),
      // 【解説】1セルの表。1つのものを枠で囲んで目立たせる使い方（README の「Tables」）。
      ('~one cell~', null),
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

  // 【解説】raw。字下げを保つ箱、文中の raw、長い行の折り返しと横スクロール、箱を消すテーマ、
  // 【解説】base と theme.raw の文字の大きさが raw ブロックに届くこと。
  testWidgets('raw regions', (tester) async {
    // 【解説】`'word ' * 30` は 'word ' を30回つなげた文字列。1行に収まらない長さを作る。
    final long = '`${'word ' * 30}`';
    await _scene(tester, 'raw', [
      ('`\nif (x) {\n    y();\n}\n`', null),
      ('inline `a ^^ b` run', null),
      (long, null),
      (long, const NaturalBlockTheme(rawScrollsHorizontally: true)),
      ('`no box`', const NaturalBlockTheme(rawDecoration: BoxDecoration())),
      ('`x`', const NaturalBlockTheme(base: TextStyle(fontSize: 24))),
      ('`x`', const NaturalBlockTheme(raw: TextStyle(fontSize: 24))),
    ]);
  });

  // 【解説】装飾。1行目は周りの色の組から、2行目は既定の NaturalBlockTheme の色で同じ文を描く。
  // 【解説】大きさの段階、重ねた装飾、base を 24 にしたとき色付きの run も24で描かれることと段階の数え方。
  testWidgets('decorations and themes', (tester) async {
    const marks = ':!neg:! :%pos:% :*em:* :@custom:@ plain';
    await _scene(tester, 'decorations', [
      (marks, null),
      (marks, const NaturalBlockTheme()),
      (':+one|:++two|:-down', null),
      (':!*+marked:!*+plain', null),
      (
        ':!toned:! plain :+bigger',
        const NaturalBlockTheme(base: TextStyle(fontSize: 24)),
      ),
    ]);
  });

  // 【解説】全部を入れ子にした1つの文書。個々の規則は上の5枚で見て、ここは組み合わせても
  // 【解説】互いを壊さないことを見る。隣り合う文字列リテラルは1つの文字列としてつながる。
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
