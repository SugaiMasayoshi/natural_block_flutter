// 【解説】読む順番 6/9：カスタム run のハンドラの決まり（順番・辞退・解放）。
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

import '../rendered_spans.dart';

// 【解説】`user(名前)` の形だけを引き受け、名前だけの文字に描き直すハンドラ。
// 【解説】それ以外の形なら null を返して辞退する（次のハンドラに回る）。
// 【解説】`条件 ? (…) : null` の `(span: …, dispose: …)` は record（名前付きの組）。
// 【解説】`substring(5, length - 1)` で先頭の `user(` と最後の `)` を落としている。
RunRendering? _mentions(
  String text,
  TextStyle style,
  NaturalBlockTheme theme,
) => text.startsWith('user(') && text.endsWith(')')
    ? (
        span: TextSpan(text: text.substring(5, text.length - 1), style: style),
        dispose: () {},
      )
    : null;

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: DefaultTextStyle(
      style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
      child: child,
    ),
  );

  // 【解説】README の「Custom text」と「Semantics」の約束。tappableText で描いた run だけが押せて
  // 【解説】読み上げられ、押すとその run の文字が onTap に渡る。ハンドラが無ければ下線は付くが、押せず
  // 【解説】読み上げもされない（押せないものを押せると伝えないため）。
  // 【解説】`.onTap!()` は認識器のタップ処理を直接呼ぶ（実際の指の操作は通さない）。
  group('tappableText', () {
    testWidgets('makes only the custom run tappable, and reports its text', (
      tester,
    ) async {
      final tapped = <String>[];
      await tester.pumpWidget(
        wrap(
          NaturalBlockView(
            source: ':@tap me:@ plain',
            customs: [
              (text, style, theme) =>
                  tappableText(text, style, onTap: tapped.add),
            ],
          ),
        ),
      );

      final spans = renderedSpans(tester);
      expect(spans.last.recognizer, isNull, reason: 'not custom');
      expect(spans.first.semanticsLabel, 'tap me');

      (spans.first.recognizer! as TapGestureRecognizer).onTap!();
      expect(tapped, ['tap me']);
    });

    testWidgets('with no handler a custom run is neither tappable nor '
        'announced', (tester) async {
      await tester.pumpWidget(
        wrap(const NaturalBlockView(source: ':@tap me:@')),
      );

      final span = renderedSpans(tester).single;
      expect(span.style!.decoration, TextDecoration.underline);
      expect(span.recognizer, isNull);
      expect(span.semanticsLabel, isNull);
    });
  });

  // 【解説】README の「Drawing a custom run yourself」の約束。ハンドラは順に聞かれ、null で辞退し、
  // 【解説】最初に答えたものが描き、返した dispose は一度だけ呼ばれる。
  group('Drawing a custom run yourself', () {
    // 【解説】1行に2つのカスタム run。`user(alice)` は _mentions が引き受けて「alice」に描き直す
    // 【解説】（ハンドラは表示する文字そのものを変えられる）。画像の方は _mentions が辞退し、
    // 【解説】次の画像ハンドラが Image にする。
    testWidgets('a handler may rewrite a run, and one that declines leaves it '
        'to the next', (tester) async {
      await tester.pumpWidget(
        wrap(
          const NaturalBlockView(
            source: ':@user(alice):@ and :@image(https://example.com/a.png):@',
            customs: [_mentions, NaturalBlockImages.network],
          ),
        ),
      );

      expect(renderedSpans(tester).first.text, 'alice');
      expect(find.byType(Image), findsOneWidget);
    });

    // 【解説】2つとも引き受けるハンドラなら、先のものが描き、後のものは呼ばれもしないこと
    // 【解説】（呼ばれた回数 asked が0のまま）。
    testWidgets('when two handlers claim a run, the first draws it', (
      tester,
    ) async {
      var asked = 0;
      RunRendering? second(String text, TextStyle style, NaturalBlockTheme _) {
        asked++;
        return (span: TextSpan(text: 'second'), dispose: () {});
      }

      RunRendering? first(String text, TextStyle style, NaturalBlockTheme _) =>
          (span: TextSpan(text: 'first'), dispose: () {});

      await tester.pumpWidget(
        MaterialApp(
          home: NaturalBlockView(source: ':@x:@', customs: [first, second]),
        ),
      );

      expect(renderedSpans(tester).single.text, 'first');
      expect(asked, 0, reason: 'the second is not asked once the first claims');
    });

    // 【解説】ハンドラが返した dispose が、ちょうど良いときに1回ずつ呼ばれること。
    // 【解説】同じ中身で描き直しても呼ばれない(0)、行の中身が変わると前の span の分が呼ばれる(1)、
    // 【解説】画面から外れると今の span の分が呼ばれる(2)。released++ で回数を数えている。
    testWidgets('the dispose a handler hands back is called, once', (
      tester,
    ) async {
      var released = 0;
      RunRendering? counting(
        String text,
        TextStyle style,
        NaturalBlockTheme theme,
      ) =>
          (span: TextSpan(text: text, style: style), dispose: () => released++);

      final customs = <RunHandler>[counting];
      Widget view(String source) => MaterialApp(
        home: NaturalBlockView(source: source, customs: customs),
      );

      await tester.pumpWidget(view('one :@x:@'));
      expect(released, 0);

      await tester.pumpWidget(view('one :@x:@'));
      expect(released, 0, reason: 'nothing it was built from changed');

      await tester.pumpWidget(view('two :@x:@'));
      expect(released, 1, reason: 'the line was rebuilt, so the span went');

      await tester.pumpWidget(const SizedBox.shrink());
      expect(released, 2, reason: 'the line left the tree');
      expect(tester.takeException(), isNull);
    });
  });
}
