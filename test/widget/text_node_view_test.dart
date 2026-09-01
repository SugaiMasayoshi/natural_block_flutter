import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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

    testWidgets('combines color and emphasis on the same span', (
      tester,
    ) async {
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
        MaterialApp(home: TextNodeView(node: node, theme: theme)),
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

    testWidgets(
      'clamps a large negative sizeOffset to minFontSize instead of '
      'producing a zero or negative font size',
      (tester) async {
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
      },
    );
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
        MaterialApp(home: TextNodeView(node: node, theme: theme)),
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
        MaterialApp(home: TextNodeView(node: node, theme: theme)),
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
          MaterialApp(home: TextNodeView(node: node, theme: theme)),
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

    testWidgets(
      'rebuilding and unmounting a tree of actionable spans does not throw '
      '(regression guard for recognizer disposal -- see note below)',
      (tester) async {
        // This does not independently *prove* the recognizers were
        // disposed, and that is a real limit rather than an oversight.
        // GestureRecognizer.dispose() is just
        // `assert(debugMaybeDispatchDisposed(this))`: it reports to the
        // opt-in leak tracker and sets no flag, and addPointer has no
        // used-after-dispose check -- so a disposed recognizer is
        // indistinguishable from a live one to anything a widget test can
        // call. (Driving the leak tracker from here was tried: it reports
        // a non-disposed object only after it is garbage collected, which
        // this test cannot force, so it passed even with disposal removed
        // -- a green test proving nothing, which is worse than none.)
        //
        // What this does verify honestly: rebuilding TextNodeView with a
        // different node (dropping the previous TapGestureRecognizers) and
        // then unmounting produces no exception -- the visible symptom if
        // TextNodeView ever disposed the same recognizer twice or used one
        // after disposing it.
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
        expect(
          renderedSpans(tester).single.recognizer,
          isA<TapGestureRecognizer>(),
        );
        expect(tester.takeException(), isNull);

        // Rebuilds with a different node, each superseding the previous
        // recognizer: the old batch must be disposed before the new one is
        // created, or Flutter's own asserts would fire here or below.
        for (final text in ['tap again', 'and again', 'once more']) {
          await pumpWith(text);
          expect(tester.takeException(), isNull);
        }

        // Unmount entirely: dispose() must clean up the last batch.
        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.takeException(), isNull);
      },
    );
  });
}
