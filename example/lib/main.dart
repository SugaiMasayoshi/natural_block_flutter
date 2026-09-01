import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

void main() {
  runApp(const MyApp());
}

/// Lets you see the sample list from [NaturalBlockDemoPage] instantly via
/// `flutter widget-preview`, without building/launching the whole example
/// app. Run `flutter widget-preview start` from this package and open the
/// preview surface it prints -- edits to `_samples` below show up live.
@Preview(name: 'natural_block_flutter サンプル一覧')
Widget naturalBlockSamplesPreview() => const NaturalBlockDemoPage();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'natural_block_flutter example',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      home: const NaturalBlockDemoPage(),
    );
  }
}

class _Sample {
  final String title;
  final String source;
  const _Sample(this.title, this.source);
}

const _samples = [
  _Sample('プレーンテキスト', 'Hello, natural_block!'),
  _Sample('セマンティックスタイル', ':!危険:!通常:?情報:?通常:%成功:%通常:*強調:*'),
  _Sample(
    '色と太字を同時に(1つの:にまとめて書く、共通の::でまとめて閉じる)',
    ':!*緊急対応をお願いします::普通のテキスト',
  ),
  _Sample(
    '記号の衝突安全性\n(単発の!?%*+-は常にただの文字)',
    'Really?! It\'s on sale for 50% off, well-known and 10-20 people say it\'s *great*!',
  ),
  _Sample(
    '文字サイズ\n(:+++で3段階、:で始めれば連打だけでOK)',
    ':++大きい:--標準サイズ',
  ),
  _Sample(
    '2セルの横並び',
    '左のセル=右のセル',
  ),
  _Sample(
    '3セルの横並び',
    '1番目=2番目=3番目',
  ),
  _Sample(
    '縦並び(Column)',
    '1行目|2行目|3行目',
  ),
  _Sample(
    '縦並びの中に横並びが混在',
    '見出し|左=右|フッター',
  ),
  _Sample(
    'ブロックの整列(<開始/^中央/>終端)、価格を右揃えにした商品テーブル',
    '|<品名=^数量=>価格|'
    '|<りんご=^3=>150|'
    '|<みかん=^12=>480|'
    '|<ぶどう=^1=>1280|',
  ),
  _Sample(
    'アクション可能なテキスト(:@...:@で囲む、下のサンプルではタップするとSnackBarを表示)',
    ':@https://example.com/docs:@ を参照|:@#はじめに:@ にジャンプ',
  ),
];

class NaturalBlockDemoPage extends StatelessWidget {
  const NaturalBlockDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('natural_block_flutter example')),
      body: Column(
        children: [
          const _Playground(),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _samples.length,
              separatorBuilder: (context, index) => const Divider(height: 32),
              itemBuilder: (context, index) {
                final sample = _samples[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sample.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sample.source,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      // タップされたアクションのテキストをそのままSnackBarで表示する。
                      // どう解釈する(URLを開く/セクションへ移動する等)かはアプリ側の
                      // 責務であり、natural_block/natural_block_flutterはテキストを
                      // 運ぶだけで一切解釈しない。
                      child: NaturalBlockView(
                        source: sample.source,
                        onActionTap: (text) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('タップされたアクション: $text')),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// A live "type it yourself" area: whatever you type in the text field is
/// parsed and rendered immediately below, using the exact same
/// [NaturalBlockView] the samples below use.
class _Playground extends StatefulWidget {
  const _Playground();

  @override
  State<_Playground> createState() => _PlaygroundState();
}

class _PlaygroundState extends State<_Playground> {
  final _controller = TextEditingController(
    text: ':!*自由に書き換えて試してみよう:!:*\n:+++大きく:--標準に戻す\n左のセル=右のセル',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('試してみよう', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            maxLines: 4,
            minLines: 2,
            style: const TextStyle(fontFamily: 'monospace'),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              filled: true,
              hintText: '記法を入力...',
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            // AnimatedBuilder listens to the controller (a Listenable) and
            // rebuilds just this preview on every keystroke.
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) =>
                  NaturalBlockView(source: _controller.text),
            ),
          ),
        ],
      ),
    );
  }
}
