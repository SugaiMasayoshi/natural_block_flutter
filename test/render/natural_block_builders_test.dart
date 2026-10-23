// 【解説】読む順番 8/9：ビルダの差し替えと比較。描き方そのものを変えたい人向けの拡張口。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:natural_block/natural_block.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

import '../rendered_spans.dart';

// 【解説】既定とは違うビルダを作るための、何もしないビルダ6つ。名前のあるトップレベル関数は
// 【解説】同じもの同士が == で等しくなるので、比較のテストに使える。
Widget _row(RowNode node, NaturalBlockScope scope) => const SizedBox();
Widget _column(ColumnNode node, NaturalBlockScope scope) => const SizedBox();
Widget _table(TableNode node, NaturalBlockScope scope) => const SizedBox();
Widget _tableCell(TableCellNode node, NaturalBlockScope scope) =>
    const SizedBox();
Widget _text(TextNode node, NaturalBlockScope scope) => const SizedBox();
Widget _raw(RawNode node, NaturalBlockScope scope) => const SizedBox();

void main() {
  // 【解説】NaturalBlockBuilders の == が6つのビルダを全部見ているか。1つでも比較から漏れると、
  // 【解説】そのビルダを差し替えても文書が描き直されない。
  group('NaturalBlockBuilders equality', () {
    // 【解説】種類ごとに「その1つだけ差し替えた組」を用意する。
    const variants = <String, NaturalBlockBuilders>{
      'row': NaturalBlockBuilders(row: _row),
      'column': NaturalBlockBuilders(column: _column),
      'table': NaturalBlockBuilders(table: _table),
      'tableCell': NaturalBlockBuilders(tableCell: _tableCell),
      'text': NaturalBlockBuilders(text: _text),
      'raw': NaturalBlockBuilders(raw: _raw),
    };

    // 【解説】Map を回して種類ごとに test を1つずつ作る（テスト名に種類名が入る）。
    for (final entry in variants.entries) {
      test('${entry.key} is part of equality', () {
        // 【解説】既定と等しくないこと。その項目が比較に入っていなければ、既定と等しくなってしまう。
        expect(entry.value, isNot(NaturalBlockBuilders.defaults));
      });
    }
  });

  // 【解説】入れ子の中（行のセル、表のセル）も、scope のビルダとハンドラで描かれること。
  // 【解説】README の「NaturalBlockBuilders」の、どこにあってもそのビルダが描くという約束。
  group('nested nodes are drawn through the scope', () {
    Future<void> pump(
      WidgetTester tester,
      String source,
      NaturalBlockBuilders builders,
    ) => tester.pumpWidget(
      MaterialApp(
        home: NaturalBlockView(source: source, builders: builders),
      ),
    );

    // 【解説】`a^b` の2つのセルは ColumnNode。column ビルダを差し替えると2つとも Placeholder になる。
    testWidgets('a row cell is a column', (tester) async {
      await pump(
        tester,
        'a^b',
        NaturalBlockBuilders(column: (node, scope) => const Placeholder()),
      );

      expect(find.byType(Placeholder), findsNWidgets(2));
      expect(find.byType(TextNodeView), findsNothing);
    });

    // 【解説】行のセル（a）と表のセル（b）にあるカスタム run が、どちらも押せる文字になること。
    // 【解説】段落（RichText）は別々なので、全部の段落を順に見て、認識器を持つ run の文字を集めている。
    testWidgets('the handlers reach a run in a row cell and a table cell', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NaturalBlockView(
            source: '|x^:@a:@|~:@b:@^c~',
            customs: [
              (text, style, theme, decoration) =>
                  tappableText(text, style, onTap: (_) {}),
            ],
          ),
        ),
      );

      final paragraphs = find.byType(RichText).evaluate().length;
      final tappable = [
        for (var i = 0; i < paragraphs; i++)
          for (final span in renderedSpans(tester, index: i))
            if (span.recognizer != null) span.text,
      ];
      expect(tappable, ['a', 'b']);
    });

    // 【解説】`~a^b~` の2つのセルは TableCellNode。tableCell ビルダを差し替えると2つとも Placeholder になる。
    testWidgets('a table cell is a tableCell', (tester) async {
      await pump(
        tester,
        '~a^b~',
        NaturalBlockBuilders(tableCell: (node, scope) => const Placeholder()),
      );

      expect(find.byType(Placeholder), findsNWidgets(2));
      expect(find.byType(TextNodeView), findsNothing);
    });
  });
}
