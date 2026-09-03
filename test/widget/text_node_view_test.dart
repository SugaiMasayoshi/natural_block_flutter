// 【解説】[テスト12/21] 葉の描画。色・サイズ・アクションが文字に届くこと。
// 【解説】
// 【解説】 サイズの group が見どころ。パーサは相対値(+2)しか言わないので、
// 【解説】 1段が何ポイントかを決めるのはテーマ。周囲の DefaultTextStyle が
// 【解説】 あればそこから、無ければ baseFontSize から数える。
// 【解説】 :----- のような大きな負値で 0 以下にならないこと(Flutter が
// 【解説】 assert する)も見ている。
// 【解説】
// 【解説】 アクションの group には、再ビルドを跨いで recognizer が同じ
// 【解説】 オブジェクトのままであることのテストがある。作り直すと押下と離上の
// 【解説】 間でタップが黙って消えるという、旧実装で実際に起きた不具合。
// 【解説】 破棄そのものは検証できない(dispose は印を残さない)ので、
// 【解説】 観測できる側だけを見ている。
// 【解説】 次: test/widget/verbatim_test.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

import '../rendered_spans.dart';

void main() {
  group('color and emphasis', () {
    testWidgets('renders each TextSpanNode with its semantic style', (
      tester,
    ) async {
      final node = TextNode(
        children: [
          TextSpanNode(text: 'danger', color: SemanticColor.danger),
          TextSpanNode(text: 'plain'),
        ],
      );
      const theme = NaturalBlockTheme();

      await tester.pumpWidget(
        MaterialApp(
          home: TextNodeView(node: node, theme: theme),
        ),
      );

      final spans = renderedSpans(tester);

      expect(spans[0].text, 'danger');
      expect(spans[0].style!.color, theme.danger.color);
      expect(spans[1].text, 'plain');
    });

    testWidgets('combines color and emphasis on the same span', (tester) async {
      final node = TextNode(
        children: [
          TextSpanNode(
            text: 'urgent',
            color: SemanticColor.danger,
            emphasis: true,
          ),
        ],
      );
      const theme = NaturalBlockTheme();

      await tester.pumpWidget(
        MaterialApp(
          home: TextNodeView(node: node, theme: theme),
        ),
      );

      final span = renderedSpans(tester).first;

      expect(span.style!.color, theme.danger.color);
      expect(span.style!.fontWeight, theme.emphasis.fontWeight);
    });
  });

  group('font size scaling', () {
    testWidgets('applies sizeOffset relative to the ambient font size', (
      tester,
    ) async {
      final node = TextNode(
        children: [TextSpanNode(text: 'big', sizeOffset: 2)],
      );
      const theme = NaturalBlockTheme();

      await tester.pumpWidget(
        MaterialApp(
          home: DefaultTextStyle(
            style: const TextStyle(fontSize: 14),
            child: TextNodeView(node: node, theme: theme),
          ),
        ),
      );

      final span = renderedSpans(tester).first;

      expect(span.style!.fontSize, 14 + 2 * theme.fontSizeStep);
    });

    testWidgets('clamps a large negative sizeOffset to minFontSize instead of '
        'producing a zero or negative font size', (tester) async {
      final node = TextNode(
        children: [TextSpanNode(text: 'tiny', sizeOffset: -5)],
      );
      const theme = NaturalBlockTheme();

      await tester.pumpWidget(
        MaterialApp(
          home: DefaultTextStyle(
            style: const TextStyle(fontSize: 14),
            child: TextNodeView(node: node, theme: theme),
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      final span = renderedSpans(tester).first;

      expect(span.style!.fontSize, theme.minFontSize);
      expect(span.style!.fontSize, greaterThan(0));
    });
  });

  group('actionable spans', () {
    testWidgets('applies the action style to an actionable span', (
      tester,
    ) async {
      final node = TextNode(
        children: [TextSpanNode(text: 'tap me', isAction: true)],
      );
      const theme = NaturalBlockTheme();

      await tester.pumpWidget(
        MaterialApp(
          home: TextNodeView(node: node, theme: theme),
        ),
      );

      final span = renderedSpans(tester).first;
      expect(span.style!.color, theme.action.color);
      expect(span.style!.decoration, theme.action.decoration);
    });

    testWidgets('combines action and emphasis styles on the same span', (
      tester,
    ) async {
      final node = TextNode(
        children: [
          TextSpanNode(text: 'tap me', isAction: true, emphasis: true),
        ],
      );
      const theme = NaturalBlockTheme();

      await tester.pumpWidget(
        MaterialApp(
          home: TextNodeView(node: node, theme: theme),
        ),
      );

      final span = renderedSpans(tester).first;
      expect(span.style!.color, theme.action.color);
      expect(span.style!.decoration, theme.action.decoration);
      expect(span.style!.fontWeight, theme.emphasis.fontWeight);
    });

    testWidgets(
      'an actionable span gets a recognizer when onActionTap is given',
      (tester) async {
        final node = TextNode(
          children: [TextSpanNode(text: 'tap me', isAction: true)],
        );
        const theme = NaturalBlockTheme();

        await tester.pumpWidget(
          MaterialApp(
            home: TextNodeView(
              node: node,
              theme: theme,
              actions: NaturalBlockActions(onTap: (_) {}),
            ),
          ),
        );

        final span = renderedSpans(tester).first;
        expect(span.recognizer, isA<TapGestureRecognizer>());
      },
    );

    testWidgets(
      'an actionable span gets no recognizer when onActionTap is null',
      (tester) async {
        final node = TextNode(
          children: [TextSpanNode(text: 'tap me', isAction: true)],
        );
        const theme = NaturalBlockTheme();

        await tester.pumpWidget(
          MaterialApp(
            home: TextNodeView(node: node, theme: theme),
          ),
        );

        final span = renderedSpans(tester).first;
        expect(span.recognizer, isNull);
      },
    );

    testWidgets('a non-actionable span gets no recognizer', (tester) async {
      final node = TextNode(children: [TextSpanNode(text: 'plain')]);
      const theme = NaturalBlockTheme();

      await tester.pumpWidget(
        MaterialApp(
          home: TextNodeView(
            node: node,
            theme: theme,
            actions: NaturalBlockActions(onTap: (_) {}),
          ),
        ),
      );

      final span = renderedSpans(tester).first;
      expect(span.recognizer, isNull);
    });

    testWidgets(
      'tapping an actionable span calls onActionTap with exactly that '
      "span's text",
      (tester) async {
        final tapped = <String>[];
        final node = TextNode(
          children: [
            TextSpanNode(text: 'actionable', isAction: true),
            TextSpanNode(text: ' plain'),
          ],
        );
        const theme = NaturalBlockTheme();

        await tester.pumpWidget(
          MaterialApp(
            home: TextNodeView(
              node: node,
              theme: theme,
              actions: NaturalBlockActions(onTap: tapped.add),
            ),
          ),
        );

        final span = renderedSpans(tester).first;
        (span.recognizer as TapGestureRecognizer).onTap!();

        expect(tapped, ['actionable']);
      },
    );

    testWidgets('tapping a non-actionable span does not fire onActionTap', (
      tester,
    ) async {
      final tapped = <String>[];
      final node = TextNode(
        children: [
          TextSpanNode(text: 'actionable', isAction: true),
          TextSpanNode(text: ' plain'),
        ],
      );
      const theme = NaturalBlockTheme();

      await tester.pumpWidget(
        MaterialApp(
          home: TextNodeView(
            node: node,
            theme: theme,
            actions: NaturalBlockActions(onTap: tapped.add),
          ),
        ),
      );

      final plainSpan = renderedSpans(tester)[1];
      expect(plainSpan.recognizer, isNull);
      expect(tapped, isEmpty);
    });

    testWidgets('only a run that actually does something is announced', (
      tester,
    ) async {
      // Style follows the document -- it said the run is actionable, so it
      // renders as such either way. Semantics follow what will actually
      // happen: telling a screen reader a run is interactive when no
      // handler is wired is a promise nothing keeps.
      final node = TextNode(
        children: [TextSpanNode(text: 'tap me', isAction: true)],
      );
      const theme = NaturalBlockTheme();

      await tester.pumpWidget(
        MaterialApp(
          home: TextNodeView(node: node, theme: theme),
        ),
      );
      final inert = renderedSpans(tester).single;
      expect(inert.style!.decoration, theme.action.decoration);
      expect(
        inert.semanticsLabel,
        isNull,
        reason: 'no handler, so nothing is announced as interactive',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TextNodeView(
            node: node,
            theme: theme,
            actions: NaturalBlockActions(onTap: (_) {}),
          ),
        ),
      );
      expect(renderedSpans(tester).single.semanticsLabel, 'tap me');
    });

    testWidgets('a recognizer survives a rebuild rather than being replaced', (
      tester,
    ) async {
      // The property the whole design turns on. A recognizer that has taken
      // a pointer down owns an entry in the gesture arena; replacing it
      // mid-gesture throws that entry away. Reusing the object is what makes
      // the next test possible.
      const theme = NaturalBlockTheme();

      Future<void> pumpWith(String text) => tester.pumpWidget(
        MaterialApp(
          home: TextNodeView(
            node: TextNode(
              children: [TextSpanNode(text: text, isAction: true)],
            ),
            theme: theme,
            actions: NaturalBlockActions(onTap: (_) {}),
          ),
        ),
      );

      await pumpWith('tap me');
      final first = renderedSpans(tester).single.recognizer;

      await pumpWith('tap again');
      expect(
        renderedSpans(tester).single.recognizer,
        same(first),
        reason: 'the same recognizer object is reused across builds',
      );
    });

    testWidgets('a tap interrupted by a rebuild still fires', (tester) async {
      // The regression this design exists for, and the only test here that
      // exercises the real gesture path -- calling `recognizer.onTap!()`
      // directly bypasses the arena, so it cannot see this at all.
      //
      // Rebuilds between a pointer down and its up are ordinary: an
      // animation, an ambient InheritedWidget changing, a SelectionArea
      // updating during a drag. When `build` recreated recognizers, the one
      // holding the down was disposed and the tap vanished silently.
      final tapped = <String>[];

      Future<void> pump(String suffix) => tester.pumpWidget(
        MaterialApp(
          home: DefaultTextStyle(
            style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
            child: TextNodeView(
              node: TextNode(
                children: [TextSpanNode(text: 'press', isAction: true)],
              ),
              // A different theme instance each time, so the rebuild is
              // real work rather than an identical widget Flutter can skip.
              theme: NaturalBlockTheme(
                base: TextStyle(letterSpacing: suffix.length * 0.0),
              ),
              actions: NaturalBlockActions(onTap: tapped.add),
            ),
          ),
        ),
      );

      await pump('a');

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

      final gesture = await tester.startGesture(target);
      await pump('bb'); // rebuild while the pointer is still down
      await gesture.up();
      await tester.pump();

      expect(tapped, [
        'press',
      ], reason: 'the tap must survive a rebuild between down and up');
    });

    testWidgets('unmounting a line of actionable spans does not throw', (
      tester,
    ) async {
      // Disposal itself stays unobservable: GestureRecognizer.dispose only
      // reports to the opt-in leak tracker, and addPointer has no
      // used-after-dispose check, so a widget test cannot distinguish a
      // disposed recognizer from a live one. (The leak tracker was tried --
      // it reports a non-disposed object only once it is garbage collected,
      // which a test cannot force, so it stayed green with disposal removed:
      // a test proving nothing, which is worse than none.)
      //
      // What is checkable is that shrinking the line and then unmounting it
      // raises nothing -- the visible symptom of a double dispose or a use
      // after one.
      const theme = NaturalBlockTheme();

      Future<void> pumpWith(List<TextSpanNode> spans) => tester.pumpWidget(
        MaterialApp(
          home: TextNodeView(
            node: TextNode(children: spans),
            theme: theme,
            actions: NaturalBlockActions(onTap: (_) {}),
          ),
        ),
      );

      await pumpWith([
        TextSpanNode(text: 'one', isAction: true),
        TextSpanNode(text: 'two', isAction: true),
        TextSpanNode(text: 'three', isAction: true),
      ]);
      expect(tester.takeException(), isNull);

      // Fewer actionable spans than before: the surplus recognizers are
      // released here rather than at unmount.
      await pumpWith([TextSpanNode(text: 'one', isAction: true)]);
      expect(tester.takeException(), isNull);

      await pumpWith([TextSpanNode(text: 'plain')]);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    });
  });
}
