// 【解説】読む順番 3/9：全体の入口。選択、描き直しの条件、幅が無限のときなど、画像に出ないこと。
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

import '../rendered_spans.dart';

// 【解説】カスタム run を 20×10 の箱（ウィジェット）として描くハンドラ。選択のテストで使う。
RunRendering? _boxed(
  String text,
  TextStyle style,
  NaturalBlockTheme theme,
  SpanDecoration decoration,
) => widgetRun(const SizedBox(width: 20, height: 10));

// 【解説】押されても何もしないタップ処理。
void _ignore(String _) {}

// 【解説】どんなカスタム run でも押せる文字にするハンドラ。
RunRendering? _links(
  String text,
  TextStyle style,
  NaturalBlockTheme theme,
  SpanDecoration decoration,
) => tappableText(text, style, onTap: _ignore);

void main() {
  // 【解説】README の「Selectable text」の約束。SelectionArea で包むと文字を選択・コピーできること。
  group('Selectable text', () {
    // 【解説】マウスで文書の先頭から末尾までドラッグすると、行のセル（a, b）、箱を含む行（c d）、
    // 【解説】raw ブロック（raw）、最後の行（e）の文字が全部、順番どおりに選択されること。
    // 【解説】`` `raw` `` を行の頭に置くと raw ブロックになる（`|` の直後だと文中の raw になってしまう）。
    testWidgets('a drag selects across cells, rows, a box and a raw block', (
      tester,
    ) async {
      // 【解説】SelectionArea が選択の変わるたびに中身を渡してくるので、最後のものをここに取っておく。
      SelectedContent? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: SelectionArea(
            onSelectionChanged: (content) => selected = content,
            child: const NaturalBlockView(
              source: 'a^b|c :@x:@ d\n`raw`\ne',
              customs: [_boxed],
            ),
          ),
        ),
      );

      final paragraphs = find.byType(RichText);
      // 【解説】最初の段落の左上から、最後の段落の右下までマウスで引く。`kind: PointerDeviceKind.mouse` は
      // 【解説】指ではなくマウスの操作にする指定（指だと長押しで選択が始まる）。
      final drag = await tester.startGesture(
        tester.getTopLeft(paragraphs.first) + const Offset(1, 1),
        kind: PointerDeviceKind.mouse,
      );
      await drag.moveTo(
        tester.getBottomRight(paragraphs.last) - const Offset(1, 1),
      );
      await drag.up();
      await tester.pump();

      expect(tester.takeException(), isNull);
      // 【解説】段落の間に空白や改行が入るかは Flutter が決めることなので、空白類（`\s`）を消してから比べる。
      expect(selected!.plainText.replaceAll(RegExp(r'\s'), ''), 'abcdrawe');
    });
  });

  // 【解説】描いた結果を使い回すこと。同じ材料なら作り直さず、変わったところだけ作り直す。
  group('the document is drawn once per source, not once per frame', () {
    // 【解説】ハンドラは BuildContext を受け取らない。周りの情報（画面の幅など）を読みたいときは、
    // 【解説】Builder を返せば Flutter がその依存を追い、幅が 300→500 に変われば表示も変わること。
    testWidgets('a handler reading an inherited widget sees it change', (
      tester,
    ) async {
      RunRendering? reads(
        String text,
        TextStyle style,
        NaturalBlockTheme theme,
        SpanDecoration decoration,
      ) => widgetRun(
        Builder(
          builder: (context) =>
              Text('${MediaQuery.sizeOf(context).width.round()}'),
        ),
      );

      final customs = <RunHandler>[reads];
      Widget view(double width) => MediaQuery(
        data: MediaQueryData(size: Size(width, 600)),
        child: MaterialApp(
          home: NaturalBlockView(source: ':@x:@', customs: customs),
        ),
      );

      await tester.pumpWidget(view(300));
      expect(find.text('300'), findsOneWidget);

      await tester.pumpWidget(view(500));
      expect(find.text('500'), findsOneWidget);
    });

    // 【解説】ビルダも同じ。Builder を返せば、文書は使い回したまま、その行だけが新しい幅を読む。
    testWidgets('a builder reading an inherited widget sees it change', (
      tester,
    ) async {
      final builders = NaturalBlockBuilders(
        text: (node, scope) => Builder(
          builder: (context) =>
              Text('${MediaQuery.sizeOf(context).width.round()}'),
        ),
      );

      Widget view(double width) => MediaQuery(
        data: MediaQueryData(size: Size(width, 600)),
        child: MaterialApp(
          home: NaturalBlockView(source: 'anything', builders: builders),
        ),
      );

      await tester.pumpWidget(view(300));
      expect(find.text('300'), findsOneWidget);

      await tester.pumpWidget(view(500));
      expect(find.text('500'), findsOneWidget);
    });

    // 【解説】2行のうち1行だけを書き換えると、作り直すのはその行だけであること。
    // 【解説】ハンドラは呼ばれた回数を数えるだけで何も描かない（null を返して辞退する）。
    // 【解説】最初は2行とも呼ばれて2回、1行目だけ変えると1回。
    testWidgets('editing one line leaves the other lines as they were', (
      tester,
    ) async {
      var calls = 0;
      RunRendering? counting(
        String text,
        TextStyle style,
        NaturalBlockTheme theme,
        SpanDecoration decoration,
      ) {
        calls++;
        return null;
      }

      final customs = <RunHandler>[counting];

      Widget view(String source) => MaterialApp(
        home: NaturalBlockView(source: source, customs: customs),
      );

      await tester.pumpWidget(view('one :@a:@|two :@b:@'));
      expect(calls, 2, reason: 'both lines built their custom span');

      calls = 0;
      await tester.pumpWidget(view('ONE :@a:@|two :@b:@'));

      expect(calls, 1, reason: 'only the edited line builds its spans again');
    });

    // 【解説】描き直すかの判断に、scope の3つ（ハンドラ・テーマ・ビルダ）が全部入っていること。
    // 【解説】1回に1つだけ変えて、それぞれで画面が変わることを確かめる（同時に変えると、どれが
    // 【解説】効いたのか分からなくなるため）。
    testWidgets('every part of the scope reaches the comparison', (
      tester,
    ) async {
      const inert = <RunHandler>[];
      const wired = <RunHandler>[_links];

      Widget view({
        NaturalBlockTheme? theme,
        NaturalBlockBuilders builders = NaturalBlockBuilders.defaults,
        List<RunHandler> customs = wired,
      }) => MaterialApp(
        home: NaturalBlockView(
          source: ':@tap:@',
          theme: theme,
          builders: builders,
          customs: customs,
        ),
      );

      await tester.pumpWidget(view(customs: inert));
      expect(renderedSpans(tester).single.recognizer, isNull);

      await tester.pumpWidget(view());
      expect(
        renderedSpans(tester).single.recognizer,
        isNotNull,
        reason: 'customs',
      );

      const sized = NaturalBlockTheme(
        custom: TextStyle(color: Color(0xFF123456)),
      );

      await tester.pumpWidget(view(theme: sized));
      expect(
        renderedSpans(tester).single.style!.color,
        const Color(0xFF123456),
        reason: 'theme',
      );

      await tester.pumpWidget(
        view(
          theme: sized,
          builders: NaturalBlockBuilders(
            text: (node, scope) => const Placeholder(),
          ),
        ),
      );
      expect(find.byType(Placeholder), findsOneWidget, reason: 'builders');
    });

    // 【解説】親が5回再構築しても、文書は作り直されないこと（ビルダの呼ばれた回数が増えない）。
    // 【解説】ValueListenableBuilder は値が変わるたびに中を作り直す。横に置いた文字が「rebuild 5」に
    // 【解説】なっていれば、親は本当に再構築されている。その文字はビルダを通らないので数に入らない。
    // 【解説】`addTearDown` はテスト後の後片付けの登録。
    testWidgets('an ancestor rebuild does not re-parse', (tester) async {
      // 【解説】text ビルダが呼ばれた回数を数える。ビルダは文書の行ごとに呼ばれるので、3行なら最初は3。
      var builds = 0;
      Widget countingText(TextNode node, NaturalBlockScope scope) {
        builds++;
        return const SizedBox.shrink();
      }

      final rebuild = ValueNotifier<int>(0);
      addTearDown(rebuild.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<int>(
            valueListenable: rebuild,
            builder: (context, value, _) => Column(
              children: [
                Text('rebuild $value'),
                NaturalBlockView(
                  source: 'one|two|three',
                  builders: NaturalBlockBuilders(text: countingText),
                ),
              ],
            ),
          ),
        ),
      );

      expect(builds, 3, reason: 'three blocks on the first build');

      for (var i = 1; i <= 5; i++) {
        rebuild.value = i;
        await tester.pump();
      }

      expect(
        find.text('rebuild 5'),
        findsOneWidget,
        reason: 'the ancestor really did rebuild',
      );
      expect(
        builds,
        3,
        reason:
            'the view hands back the very same tree, so nothing below it is '
            'built again -- not the parse, and not the widgets either',
      );
    });
  });

  // 【解説】README の「Tables」にある、幅が無限のとき（横スクロールの中など）の約束。
  group('Tables', () {
    // 【解説】横スクロールの中（幅が無限）でも、どの種類のブロック（普通の文・寄せ・raw・行・表・
    // 【解説】空白だけ）も例外にならないこと。
    testWidgets('every kind of block renders in an unbounded width', (
      tester,
    ) async {
      for (final source in [
        'plain',
        '|=A|',
        '|>A|',
        '`code here`',
        'a^b',
        '|=~A^B|C^D~',
        '   ',
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: NaturalBlockView(source: source),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull, reason: '"$source"');
      }
    });
  });
}
