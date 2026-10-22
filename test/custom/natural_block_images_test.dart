// 【解説】読む順番 7/9：画像ハンドラ。ハンドラの決まりを知ってから読むと分かりやすい。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

import '../rendered_spans.dart';

void _ignore(String _) {}

// 【解説】どんなカスタム run でも押せる文字にするハンドラ（画像が辞退したときの受け皿）。
RunRendering? _links(String text, TextStyle style, NaturalBlockTheme theme) =>
    tappableText(text, style, onTap: _ignore);

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: DefaultTextStyle(
      style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
      child: child,
    ),
  );

  // 【解説】記法から描く補助。ハンドラの既定は「ネットワーク画像 → 押せる文字」の順。
  Future<void> pumpImages(
    WidgetTester tester,
    String source, {
    NaturalBlockTheme theme = const NaturalBlockTheme(),
    List<RunHandler> customs = const [NaturalBlockImages.network, _links],
  }) => tester.pumpWidget(
    wrap(NaturalBlockView(source: source, theme: theme, customs: customs)),
  );

  // 【解説】`image(...)` の中身を取り出せること、それ以外（前後の空白、`img`、大文字など）は null。
  // 【解説】Map の値が String なら取り出せる中身、null なら辞退。URL の ? や () はそのまま残る。
  test('sourceOf reads image(...) and declines anything else', () {
    const expected = <String, String?>{
      'image(https://example.com/a.png)': 'https://example.com/a.png',
      'image(https://e.com/x.png?id=you&v=2)': 'https://e.com/x.png?id=you&v=2',
      'image(https://e.com/a_(1).png)': 'https://e.com/a_(1).png',
      'https://example.com': null,
      '#section': null,
      'image()': null,
      ' image(https://e.com/a.png)': null,
      'image(https://e.com/a.png) ': null,
      'image( https://e.com/a.png)': null,
      'image(https://e.com/a.png )': null,
      'img(https://e.com/a.png)': null,
      'IMAGE(https://e.com/a.png)': null,
      'image(https://e.com/a.png) trailing': null,
      '': null,
    };

    for (final MapEntry(key: text, value: source) in expected.entries) {
      expect(NaturalBlockImages.sourceOf(text), source, reason: '"$text"');
    }
  });

  // 【解説】取り出した中身が、ネットワーク・ローカルファイル・相対パスのどれかを判定する kindOf。
  // 【解説】`r'…'` は `\` をそのまま書ける文字列（raw 文字列）。Windows のパスに使っている。
  // 【解説】`\\server\share` は UNC（ネットワーク上の共有フォルダ）で、これもファイル扱い。
  test('kindOf classifies where a payload points', () {
    const expected = <ImageSourceKind, List<String>>{
      ImageSourceKind.network: [
        'https://example.com/a.png',
        'http://example.com/a.png',
        'https://e.com/x.png?id=you',
      ],
      ImageSourceKind.file: [
        r'C:\Users\sugai\a.png',
        'C:/Users/sugai/a.png',
        r'D:\photos\My Pictures\a.png',
        r'c:\lower\a.png',
        r'\\server\share\a.png',
        '/home/sugai/a.png',
        'file:///C:/Users/a.png',
      ],
      ImageSourceKind.relative: ['./assets/a.png', 'assets/a.png', 'a.png', ''],
    };

    // 【解説】Map の各組を「kind」と「sources」に分解して受け取る書き方（パターンでの分解）。
    for (final MapEntry(key: kind, value: sources) in expected.entries) {
      for (final source in sources) {
        expect(
          NaturalBlockImages.kindOf(source),
          kind,
          reason: '"$source" is $kind',
        );
      }
    }
  });

  // 【解説】README の「Images」「Local files」の約束。画像ハンドラとしての振る舞い。
  group('Images', () {
    // 【解説】画像の run は文字ではなく WidgetSpan になり、縦位置は middle（文字の中央に合わせる）
    // 【解説】であること。`as TextSpan` などは型を決めつけて取り出す書き方。
    // 【解説】`.children!.single` は「子がちょうど1つ」を取り出す（!は null でないと断言する記号）。
    testWidgets('an image payload becomes a WidgetSpan, not text', (
      tester,
    ) async {
      await pumpImages(tester, ':@image(https://example.com/a.png):@');

      final richText = tester.widget<RichText>(find.byType(RichText));
      final child = (richText.text as TextSpan).children!.single as TextSpan;

      expect(
        child.children!.single,
        isA<WidgetSpan>(),
        reason: 'the run renders as a widget rather than as its text',
      );
      expect(
        (child.children!.single as WidgetSpan).alignment,
        PlaceholderAlignment.middle,
        reason:
            'not `WidgetSpan`\'s own default of bottom, which leaves the '
            'text beside it hanging below the image',
      );
    });

    // 【解説】scale はテーマの基準の大きさから決まること。基準 28、周りの文字 14 なら、
    // 【解説】28 / 14 = 2（画像は半分の大きさで描かれる）。
    testWidgets('the scale follows the theme, not a hardcoded size', (
      tester,
    ) async {
      await pumpImages(
        tester,
        ':@image(https://example.com/a.png):@',
        theme: const NaturalBlockTheme(baseFontSize: 28),
      );

      final image = tester.widget<Image>(find.byType(Image).first);
      expect((image.image as NetworkImage).scale, 2);
    });

    // 【解説】画像に読み上げ用のラベル（元の URL）が付くこと。
    testWidgets('an image carries a semantic label', (tester) async {
      await pumpImages(tester, ':@image(https://example.com/a.png):@');

      expect(
        tester.widget<Image>(find.byType(Image)).semanticLabel,
        'https://example.com/a.png',
      );
    });

    // 【解説】network ハンドラはネットワークの URL だけを描き、ローカルのパスは辞退して文字のまま残すこと。
    // 【解説】ローカルのファイルを出すかはアプリが local を入れて決める、という README の約束。
    testWidgets('network declines a local path rather than fetching it', (
      tester,
    ) async {
      await pumpImages(tester, ':@image(C:/a.png):@');

      expect(find.byType(Image), findsNothing);
      expect(renderedSpans(tester).single.text, 'image(C:/a.png)');
    });

    // 【解説】取得や読み込みに失敗した画像は、`image(...)` の文字に戻ること。テストの中ではネットワークは
    // 【解説】必ず失敗し、存在しないファイルも読めない。
    // 【解説】`tester.runAsync` は本物の非同期処理（読み込みの失敗）が終わるのを待つための書き方。
    // 【解説】ふつうのテストの時間は止まっているので、これがないと失敗の知らせが届かない。
    testWidgets('an image that cannot be drawn falls back to its payload', (
      tester,
    ) async {
      for (final (payload, handler) in [
        ('image(https://example.com/a.png)', NaturalBlockImages.network),
        ('image(C:/no/such/file.png)', NaturalBlockImages.local),
      ]) {
        await tester.pumpWidget(
          wrap(NaturalBlockView(source: ':@$payload:@', customs: [handler])),
        );
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await tester.pump();

        expect(
          find.text(payload, findRichText: true),
          findsOneWidget,
          reason: 'the fetch or the read failed',
        );
      }
    });

    // 【解説】local ハンドラを入れると、ローカルのパスはファイルの画像（FileImage）になること。scale は基準 28 ÷ 周りの 14 = 2、読み上げのラベルはパスそのもの。
    testWidgets('NaturalBlockImages.local draws a local path from a file', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: r':@image(C:\a.png):@',
            theme: NaturalBlockTheme(baseFontSize: 28),
            customs: [
              NaturalBlockImages.local,
              NaturalBlockImages.network,
              _links,
            ],
          ),
        ),
      );

      final image = tester.widget<Image>(find.byType(Image));
      expect((image.image as FileImage).scale, 2);
      expect(image.semanticLabel, r'C:\a.png');
    });

    // 【解説】local は URL を辞退し、後ろの network が描くこと（両方入れても両方動く）。
    testWidgets('NaturalBlockImages.local still draws a network image', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: ':@image(https://example.com/a.png):@',
            customs: [
              NaturalBlockImages.local,
              NaturalBlockImages.network,
              _links,
            ],
          ),
        ),
      );

      expect(
        tester.widget<Image>(find.byType(Image)).image,
        isA<NetworkImage>(),
      );
    });

    // 【解説】`?v=1` の付いた file URI はパスに直せない。例外にせず辞退し、文字のまま表示すること。
    testWidgets(
      'NaturalBlockImages.local declines a file URI it cannot turn into a '
      'path, rather than throwing',
      (tester) async {
        await tester.pumpWidget(
          wrap(
            const NaturalBlockView(
              source: ':@image(file:///a.png?v=1):@',
              customs: [
                NaturalBlockImages.local,
                NaturalBlockImages.network,
                _links,
              ],
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(Image), findsNothing);
        expect(renderedSpans(tester).single.text, 'image(file:///a.png?v=1)');
      },
    );

    // 【解説】相対パスはどちらのハンドラも描かない（基準の場所はアプリしか知らないため）。
    testWidgets('NaturalBlockImages.local leaves a relative path to the app', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: ':@image(assets/a.png):@',
            customs: [
              NaturalBlockImages.local,
              NaturalBlockImages.network,
              _links,
            ],
          ),
        ),
      );

      expect(find.byType(Image), findsNothing);
      expect(renderedSpans(tester).single.text, 'image(assets/a.png)');
    });
  });
}
