// 【解説】読む順番 5/9：1行の描画とタップの記憶。このパッケージで一番大事な部分。
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

import '../rendered_spans.dart';

// 【解説】押されても何もしないタップ処理。引数名の `_` は「使わない」の意味。
void _ignore(String _) {}

// 【解説】カスタム run を押せる文字にするハンドラ。名前のあるトップレベル関数なので、毎回同じもの
// 【解説】として比較される（作り直しのテストで「ハンドラが変わっていない」状態を作るのに使う）。
RunRendering? _wired(String text, TextStyle style, NaturalBlockTheme theme) =>
    tappableText(text, style, onTap: _ignore);

// 【解説】_wired と中身は同じだが別の関数。「ハンドラが変わった」状態を作るのに使う。
RunRendering? _wiredElsewhere(
  String text,
  TextStyle style,
  NaturalBlockTheme theme,
) => tappableText(text, style, onTap: _ignore);

// 【解説】押された文字を sink に記録するハンドラ1つだけの一覧を作る。`sink.add` を onTap に渡す。
List<RunHandler> _into(List<String> sink) => [
  (text, style, theme) => tappableText(text, style, onTap: sink.add),
];

void main() {
  // 【解説】カスタム（`:@`）の印が付いた run を手で作る補助。
  TextSpanNode custom(String text) =>
      TextSpanNode(text: text, decoration: SpanDecoration(isCustom: true));

  // 【解説】run の並びから1行を作って TextNodeView で描く補助。テーマ・ハンドラ・周りの文字の書式
  // 【解説】（ambient）を差し替えられる。ハンドラの既定は _wired（押せる）。
  // 【解説】`ambient == null ? view : DefaultTextStyle(...)` は、指定があるときだけ周りの書式で包む。
  Future<void> pumpRuns(
    WidgetTester tester,
    List<InlineNode> runs, {
    NaturalBlockTheme theme = const NaturalBlockTheme(),
    List<RunHandler> customs = const [_wired],
    TextStyle? ambient,
  }) {
    final view = TextNodeView(
      node: TextNode(children: runs),
      scope: NaturalBlockScope(theme: theme, customs: customs),
    );
    return tester.pumpWidget(
      MaterialApp(
        home: ambient == null
            ? view
            : DefaultTextStyle(style: ambient, child: view),
      ),
    );
  }

  // 【解説】index 番目の span が持つタップ認識器。`[int index = 0]` は省略できる位置引数。
  GestureRecognizer? recognizerOf(WidgetTester tester, [int index = 0]) =>
      renderedSpans(tester)[index].recognizer;

  // 【解説】README の「Custom text」と「Semantics」の約束。押せる文字（カスタム run）がいつ押せて、
  // 【解説】いつ読み上げられ、作り直しの前後で押した操作が消えないこと。
  group('Custom text', () {
    // 【解説】認識器が付くのは「カスタム run」で「ハンドラが答えた」ときだけ。
    // 【解説】ハンドラ無しなら付かず、普通の run には付かない。
    testWidgets('a recognizer appears for a custom run, and only when '
        'something is wired to it', (tester) async {
      await pumpRuns(tester, [custom('tap me')]);
      expect(recognizerOf(tester), isA<TapGestureRecognizer>());

      await pumpRuns(tester, [custom('tap me')], customs: const []);
      expect(recognizerOf(tester), isNull, reason: 'nothing wired');

      await pumpRuns(tester, [TextSpanNode(text: 'plain')]);
      expect(recognizerOf(tester), isNull, reason: 'not custom');
    });

    // 【解説】押すと、その run の文字がそのまま onTap に渡ること。隣の普通の run は混ざらない。
    // 【解説】`.onTap!()` は認識器のタップ処理を直接呼ぶ（実際の指の操作は通さない）。
    testWidgets("a tap calls onTap with exactly that run's text", (
      tester,
    ) async {
      final tapped = <String>[];
      await pumpRuns(tester, [
        custom('actionable'),
        TextSpanNode(text: ' plain'),
      ], customs: _into(tapped));

      (recognizerOf(tester)! as TapGestureRecognizer).onTap!();

      expect(tapped, ['actionable']);
    });

    // 【解説】ハンドラが無いときもカスタムの見た目（下線）にはなるが、読み上げ用のラベルは付かないこと。
    // 【解説】ハンドラが答えて押せるときだけラベルが付く（押せないものを押せると伝えないため）。
    testWidgets('only a run that actually does something is announced', (
      tester,
    ) async {
      const theme = NaturalBlockTheme();

      await pumpRuns(tester, [custom('tap me')], customs: const []);
      final inert = renderedSpans(tester).single;
      expect(inert.style!.decoration, theme.custom.decoration);
      expect(
        inert.semanticsLabel,
        isNull,
        reason: 'no handler, so nothing is announced as interactive',
      );

      await pumpRuns(tester, [custom('tap me')]);
      expect(renderedSpans(tester).single.semanticsLabel, 'tap me');
    });

    // 【解説】行が span と認識器を「いつ作り直し、いつ使い続けるか」のテスト群。
    // 【解説】押している最中に認識器を作り直すとタップが消えるので、材料が変わらない限り使い続ける。
    // 【解説】`same(first)` は「同じオブジェクトである」こと、`isNot(same(first))` は作り直されたこと。
    group('the spans, and the recognizers they carry', () {
      // 【解説】同じ中身でもう一度描いても、認識器は同じもののまま。
      testWidgets('a rebuild with the same runs keeps the recognizer', (
        tester,
      ) async {
        await pumpRuns(tester, [custom('tap me')]);
        final first = recognizerOf(tester);

        await pumpRuns(tester, [custom('tap me')]);

        expect(recognizerOf(tester), same(first));
      });

      // 【解説】周りの文字の大きさが変わっても、テーマの base が大きさを決めているなら span に届かない。
      // 【解説】届かない変化では作り直さない。
      testWidgets('an ambient change the spans do not see keeps them', (
        tester,
      ) async {
        const theme = NaturalBlockTheme(base: TextStyle(fontSize: 20));

        await pumpRuns(
          tester,
          [custom('tap me')],
          theme: theme,
          ambient: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
        );
        final first = recognizerOf(tester);

        await pumpRuns(
          tester,
          [custom('tap me')],
          theme: theme,
          ambient: const TextStyle(fontSize: 30, color: Color(0xFF000000)),
        );

        expect(recognizerOf(tester), same(first));
      });

      // 【解説】ハンドラが変われば作り直す。
      testWidgets('a different handler rebuilds the spans', (tester) async {
        await pumpRuns(tester, [custom('tap me')], customs: const [_wired]);
        final first = recognizerOf(tester);

        await pumpRuns(
          tester,
          [custom('tap me')],
          customs: const [_wiredElsewhere],
        );

        expect(recognizerOf(tester), isNot(same(first)));
      });

      // 【解説】行の中身が変われば作り直す。
      testWidgets('changed runs rebuild the spans', (tester) async {
        await pumpRuns(tester, [custom('tap me')]);
        final first = recognizerOf(tester);

        await pumpRuns(tester, [custom('tap again')]);

        expect(recognizerOf(tester), isNot(same(first)));
      });

      // 【解説】テーマが変われば作り直す。
      testWidgets('a changed theme rebuilds the spans', (tester) async {
        await pumpRuns(tester, [custom('tap me')]);
        final first = recognizerOf(tester);

        await pumpRuns(tester, [
          custom('tap me'),
        ], theme: const NaturalBlockTheme(fontSizeStep: 9));

        expect(recognizerOf(tester), isNot(same(first)));
      });

      // 【解説】文中の raw run も、隣の文字と同じ根（周りの書式＋テーマの base）から書式を作ること。
      // 【解説】base が大きさを決めているとき、周りの大きさを 14→30 に変えても、raw と隣の文字が
      // 【解説】同じ大きさのまま。以前は raw だけ古い大きさが残る不具合があった。
      // 【解説】`var spans` は後で入れ直すので final ではなく var。
      testWidgets('a raw run is drawn from the same root as its neighbours', (
        tester,
      ) async {
        const theme = NaturalBlockTheme(base: TextStyle(fontSize: 20));

        Future<void> pump(double ambient) => pumpRuns(
          tester,
          [TextSpanNode(text: 'a'), RawSpanNode(text: 'code')],
          theme: theme,
          ambient: TextStyle(fontSize: ambient),
        );

        await pump(14);
        var spans = renderedSpans(tester);
        expect(spans[1].style!.fontSize, spans[0].style!.fontSize);

        await pump(30);
        spans = renderedSpans(tester);
        expect(
          spans[1].style!.fontSize,
          spans[0].style!.fontSize,
          reason: 'the raw run moves with the line or not at all',
        );
        // 【解説】既定のテーマでは raw が等幅フォントになること（README の約束）。テスト用フォントでは
        // 【解説】フォントの違いが画像に出ないので、ここで値として確かめる。
        expect(spans[1].style!.fontFamily, 'monospace');
      });

      // 【解説】base が大きさを決めていないなら、周りの大きさの変化は span に届くので作り直す。
      testWidgets('a changed ambient text style rebuilds the spans', (
        tester,
      ) async {
        await pumpRuns(tester, [
          custom('tap me'),
        ], ambient: const TextStyle(fontSize: 14));
        final first = recognizerOf(tester);

        await pumpRuns(tester, [
          custom('tap me'),
        ], ambient: const TextStyle(fontSize: 22));

        expect(recognizerOf(tester), isNot(same(first)));
      });
    });

    // 【解説】このパッケージで一番大事なテスト。指を下ろしてから離すまでの間に再構築が入っても、
    // 【解説】タップが届くこと。実際の指の操作（startGesture → up）を通している。
    testWidgets('a tap interrupted by a rebuild still fires', (tester) async {
      final tapped = <String>[];
      final customs = _into(tapped);

      // 【解説】pumpRuns は毎回新しい TextNodeView を作るので、呼ぶたびに再構築が起きる。
      // 【解説】材料（行・テーマ・ハンドラ・周りの書式）は同じなので、span は作り直されないはず。
      Future<void> pump() => pumpRuns(
        tester,
        [custom('press')],
        customs: customs,
        ambient: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
      );

      await pump();

      // 【解説】「press」の5文字を囲む矩形の中心（画面座標）を、指を下ろす位置として求める。
      final paragraph = tester.renderObject<RenderParagraph>(
        find.byType(RichText),
      );
      final box = paragraph
          .getBoxesForSelection(
            const TextSelection(baseOffset: 0, extentOffset: 5),
          )
          .single;
      final target = paragraph.localToGlobal(
        Offset((box.left + box.right) / 2, (box.top + box.bottom) / 2),
      );

      // 【解説】指を下ろす → その間に再構築 → 指を離す。認識器が作り直されていればここでタップが消える。
      final gesture = await tester.startGesture(target);
      await pump(); // rebuild while the pointer is still down
      await gesture.up();
      await tester.pump();

      expect(tapped, [
        'press',
      ], reason: 'the tap must survive a rebuild between down and up');
    });
  });
}
