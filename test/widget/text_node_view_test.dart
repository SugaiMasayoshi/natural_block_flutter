// 【解説】読む順番 5/9：1行の描画とタップの記憶。このパッケージで一番大事な部分。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

import '../rendered_spans.dart';

// 【解説】カスタム run をそのまま文字の span にするだけのハンドラ2つ。中身は同じだが別の関数なので、
// 【解説】「ハンドラが変わった」状態を作れる。認識器は持たない。
RunRendering? _plain(String text, TextStyle style, NaturalBlockTheme theme) =>
    (span: TextSpan(text: text, style: style), dispose: () {});

RunRendering? _plainElsewhere(
  String text,
  TextStyle style,
  NaturalBlockTheme theme,
) => (span: TextSpan(text: text, style: style), dispose: () {});

void main() {
  // 【解説】カスタム（`:@`）の印が付いた run を手で作る補助。
  TextSpanNode custom(String text) =>
      TextSpanNode(text: text, decoration: SpanDecoration(isCustom: true));

  // 【解説】run の並びから1行を作って TextNodeView で描く補助。テーマ・ハンドラ・周りの文字の書式
  // 【解説】（ambient）を差し替えられる。ハンドラの既定は無し。
  // 【解説】`ambient == null ? view : DefaultTextStyle(...)` は、指定があるときだけ周りの書式で包む。
  // 【解説】Align で包むので、段落は画面いっぱいに広がらず、文字の大きさに縮む。
  Future<void> pumpRuns(
    WidgetTester tester,
    List<InlineNode> runs, {
    NaturalBlockTheme theme = const NaturalBlockTheme(),
    List<RunHandler> customs = const [],
    TextStyle? ambient,
  }) {
    final view = TextNodeView(
      node: TextNode(children: runs),
      scope: NaturalBlockScope(theme: theme, customs: customs),
    );
    return tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: ambient == null
              ? view
              : DefaultTextStyle(style: ambient, child: view),
        ),
      ),
    );
  }

  // 【解説】描かれた span がただ1つのとき、それを取り出す補助。作り直されたかを `same` で比べる目印にする。
  TextSpan onlySpan(WidgetTester tester) => renderedSpans(tester).single;

  // 【解説】行が span を「いつ作り直し、いつ使い続けるか」のテスト群。span が持つ認識器も一緒に
  // 【解説】入れ替わるので、押している最中に作り直すとタップが消える。材料が変わらない限り使い続ける。
  // 【解説】`same(first)` は「同じオブジェクトである」こと、`isNot(same(first))` は作り直されたこと。
  group('when the spans are rebuilt', () {
    // 【解説】同じ中身でもう一度描いても、span は同じもののまま。
    testWidgets('a rebuild with the same runs keeps them', (tester) async {
      await pumpRuns(tester, [TextSpanNode(text: 'x')]);
      final first = onlySpan(tester);

      await pumpRuns(tester, [TextSpanNode(text: 'x')]);

      expect(onlySpan(tester), same(first));
    });

    // 【解説】周りの文字の大きさが変わっても、テーマの base が大きさを決めているなら span に届かない。
    // 【解説】届かない変化では作り直さない。
    testWidgets('an ambient change the spans do not see keeps them', (
      tester,
    ) async {
      const theme = NaturalBlockTheme(base: TextStyle(fontSize: 20));

      await pumpRuns(
        tester,
        [TextSpanNode(text: 'x')],
        theme: theme,
        ambient: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
      );
      final first = onlySpan(tester);

      await pumpRuns(
        tester,
        [TextSpanNode(text: 'x')],
        theme: theme,
        ambient: const TextStyle(fontSize: 30, color: Color(0xFF000000)),
      );

      expect(onlySpan(tester), same(first));
    });

    // 【解説】ハンドラが変われば作り直す。
    testWidgets('a different handler rebuilds them', (tester) async {
      await pumpRuns(tester, [custom('x')], customs: const [_plain]);
      final first = onlySpan(tester);

      await pumpRuns(tester, [custom('x')], customs: const [_plainElsewhere]);

      expect(onlySpan(tester), isNot(same(first)));
    });

    // 【解説】行の中身が変われば作り直す。
    testWidgets('changed runs rebuild them', (tester) async {
      await pumpRuns(tester, [TextSpanNode(text: 'x')]);
      final first = onlySpan(tester);

      await pumpRuns(tester, [TextSpanNode(text: 'y')]);

      expect(onlySpan(tester), isNot(same(first)));
    });

    // 【解説】テーマが変われば作り直す。
    testWidgets('a changed theme rebuilds them', (tester) async {
      await pumpRuns(tester, [TextSpanNode(text: 'x')]);
      final first = onlySpan(tester);

      await pumpRuns(tester, [
        TextSpanNode(text: 'x'),
      ], theme: const NaturalBlockTheme(fontSizeStep: 9));

      expect(onlySpan(tester), isNot(same(first)));
    });

    // 【解説】base が大きさを決めていないなら、周りの大きさの変化は span に届くので作り直す。
    testWidgets('a changed ambient text style rebuilds them', (tester) async {
      await pumpRuns(tester, [
        TextSpanNode(text: 'x'),
      ], ambient: const TextStyle(fontSize: 14));
      final first = onlySpan(tester);

      await pumpRuns(tester, [
        TextSpanNode(text: 'x'),
      ], ambient: const TextStyle(fontSize: 22));

      expect(onlySpan(tester), isNot(same(first)));
    });
  });

  // 【解説】文中の raw run も、隣の文字と同じ根（周りの書式＋テーマの base）から大きさを取ること。
  // 【解説】周りが 30、base が 20 なら、隣も raw も base の 20 で描かれる。
  testWidgets('a raw run takes its size from the same root as its neighbours', (
    tester,
  ) async {
    await pumpRuns(
      tester,
      [TextSpanNode(text: 'a'), RawSpanNode(text: 'code')],
      theme: const NaturalBlockTheme(base: TextStyle(fontSize: 20)),
      ambient: const TextStyle(fontSize: 30),
    );

    final spans = renderedSpans(tester);
    expect(spans[0].style!.fontSize, 20);
    expect(spans[1].style!.fontSize, 20);
    // 【解説】既定のテーマでは raw が等幅フォントになること（README の約束）。テスト用フォントでは
    // 【解説】フォントの違いが画像に出ないので、ここで値として確かめる。
    expect(spans[1].style!.fontFamily, 'monospace');
  });

  // 【解説】このパッケージで一番大事なテスト。指を下ろしてから離すまでの間に再構築が入っても、
  // 【解説】タップが届くこと。実際の指の操作（startGesture → up）を通すので、本物の認識器を持つ
  // 【解説】tappableText を使う。
  testWidgets('a tap interrupted by a rebuild still fires', (tester) async {
    final tapped = <String>[];
    final customs = <RunHandler>[
      (text, style, theme) => tappableText(text, style, onTap: tapped.add),
    ];

    // 【解説】pumpRuns は毎回新しい TextNodeView を作るので、呼ぶたびに再構築が起きる。
    // 【解説】材料（行・テーマ・ハンドラ・周りの書式）は同じなので、span は作り直されないはず。
    Future<void> pump() =>
        pumpRuns(tester, [custom('press')], customs: customs);

    await pump();

    // 【解説】段落は文字の大きさに縮んでいるので、その中心が「press」の上になる。
    // 【解説】指を下ろす → その間に再構築 → 指を離す。認識器が作り直されていればここでタップが消える。
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(RichText)),
    );
    await pump(); // rebuild while the pointer is still down
    await gesture.up();
    await tester.pump();

    expect(tapped, [
      'press',
    ], reason: 'the tap must survive a rebuild between down and up');
  });
}
