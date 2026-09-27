import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

void main() {
  runApp(const MyApp());
}

@Preview(name: 'natural_block_flutter サンプル一覧')
Widget naturalBlockSamplesPreview() => const NaturalBlockDemoPage();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var _dark = false;
  var _striped = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'natural_block_flutter example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      home: NaturalBlockDemoPage(
        dark: _dark,
        striped: _striped,
        onDarkChanged: (value) => setState(() => _dark = value),
        onStripedChanged: (value) => setState(() => _striped = value),
      ),
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
  _Sample('セマンティックスタイル', ':!危険:!通常:%成功:%通常:*強調:*'),
  _Sample('色と太字を同時に(1つの:にまとめて書く、共通の::でまとめて閉じる)', ':!*緊急対応をお願いします::普通のテキスト'),
  _Sample(
    '記号の衝突安全性\n(単発の!?%*+-は常にただの文字)',
    'Really?! It\'s on sale for 50% off, well-known and 10-20 people say it\'s *great*!',
  ),
  _Sample('文字サイズ\n(:+++で3段階、:で始めれば連打だけでOK)', ':++大きい:--標準サイズ'),
  _Sample('2セルの横並び', '左のセル^右のセル'),
  _Sample('3セルの横並び', '1番目^2番目^3番目'),
  _Sample('縦並び(Column)', '1行目|2行目|3行目'),
  _Sample('縦並びの中に横並びが混在', '見出し|左^右|フッター'),
  _Sample(
    'ブロックの整列(<開始/=中央/>終端)、価格を右揃えにした商品テーブル',
    '|<品名^=数量^>価格|'
        '|<りんご^=3^>150|'
        '|<みかん^=12^>480|'
        '|<ぶどう^=1^>1280|',
  ),
  _Sample(
    'アクション可能なテキスト(:@...:@で囲む、下のサンプルではタップするとSnackBarを表示)',
    ':@https://example.com/docs:@ を参照|:@#はじめに:@ にジャンプ',
  ),
  _Sample(
    '表(~で開始、列幅が中身に合う)\nすぐ上の「行の並び」と見比べてほしい',
    '~\n'
        '|商品^価格^在庫\n'
        '|りんご^150^12\n'
        '|バナナ^98^3\n'
        '~',
  ),
  _Sample(
    '表の列ごとの寄せ(見出し行で指定すると以降の行が受け継ぐ)',
    '~\n'
        '|商品^>価格^=在庫\n'
        '|りんご^150^12\n'
        '|バナナ^98^3\n'
        '~',
  ),
  _Sample('表を閉じる(~をもう一度書く)\n閉じないと入力の終わりまで表が続く', '~商品^価格|りんご^150~合計^150'),
  _Sample(
    '画像(構文の追加なし、image(url)というアクションの慣習)\n'
        'このアプリは NaturalBlockActions.buildSpan を渡しているので描画される。'
        '渡さなければ読めるテキストのままで通信も起きない',
    ':@image(https://flutter.github.io/assets-for-api-docs/assets/widgets/owl.jpg):@',
  ),
  _Sample(
    '画像にも :++ と寄せが効く(左が標準、右が3段階拡大)',
    '|=:@image(https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg):@'
        '^:+++:@image(https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg):@|',
  ),
  _Sample(
    r'エスケープ(\| \^ \: と、\\ でバックスラッシュそのもの)',
    r'縦棒 \| と 山記号 \^ と コロン \: はそのまま出る|'
        r'C:\Users\you\a.png はエスケープ不要|'
        r'\\^ だけは「\ のセル」と本物の区切りになる',
  ),
  _Sample('空セルで右端に飛ばす(表ではなく素の行。等分するから右端に来る)', '左^^右'),
  _Sample(
    '中央寄せの表(表は寄せを持たず、入れたブロックの寄せで置かれる)',
    '|=~記号^意味|'
        '\\|^縦に並べる|'
        '\\^^横に並べる|',
  ),
  _Sample('囲み(1セルの表で、1つのものを枠で囲む)', '~注意~'),
  _Sample('複数行のブロック(改行ごとに1ノード。装飾は改行を越えない)', '|:*1行目は太字\n2行目は普通に戻る|'),
  _Sample(
    'そのまま出す区間(バッククォートで囲む)\n単独で置くとコードブロックとして描かれる',
    '`\n'
        'final x = a == b ? 1 : 2;\n'
        'cat file.txt | grep foo | wc -l\n'
        '`',
  ),
  _Sample('= を含むコードは区間の外でも割れない\nセル区切りが ^ になったので', 'final x = a == b ? 1 : 2;'),
  _Sample('割れるのは | と ^ のほう\nだから区間が要る', 'cat file.txt | grep foo | wc -l'),
  _Sample('文中にも置ける(同じ構文・同じノード)\n置かれ方で見た目だけが変わる', '比較は `a == b` で、区切りは `|` です'),
  _Sample(
    '表のセルの中でも使える\n| を含むコードがセルを割らない',
    '~記号^意味|'
        '`|`^縦に並べる|'
        '`^`^横に並べる|',
  ),
  _Sample(
    'フェンスは長くできる(``なら中に`を書ける)\nこの記法で自分自身を説明できる',
    '``\n'
        '`これは閉じ記号にならない`\n'
        '``',
  ),
  _Sample('閉じ忘れは文書の終わりまで区間になる(表の ~ と同じ)', 'a `b の後の | も区間の中'),
];

class NaturalBlockDemoPage extends StatelessWidget {
  final bool dark;
  final bool striped;
  final ValueChanged<bool> onDarkChanged;
  final ValueChanged<bool> onStripedChanged;

  const NaturalBlockDemoPage({
    super.key,
    this.dark = false,
    this.striped = false,
    this.onDarkChanged = _ignore,
    this.onStripedChanged = _ignore,
  });

  static void _ignore(bool _) {}

  @override
  Widget build(BuildContext context) {
    final theme = NaturalBlockTheme.fromContext(context, striped: striped);

    return Scaffold(
      appBar: AppBar(
        title: const Text('natural_block_flutter example'),
        actions: [
          _Toggle(label: '縞', value: striped, onChanged: onStripedChanged),
          _Toggle(label: 'ダーク', value: dark, onChanged: onDarkChanged),
        ],
      ),
      body: SelectionArea(
        child: Column(
          children: [
            _Playground(theme: theme),
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
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: NaturalBlockView(
                          source: sample.source,
                          theme: theme,
                          actions: NaturalBlockActions(
                            buildSpan: NaturalBlockImages.builder,
                            onTap: (text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('タップされたアクション: $text')),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            _RegistryDemo(theme: theme),
          ],
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _Toggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label),
        Switch(value: value, onChanged: onChanged),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _RegistryDemo extends StatelessWidget {
  final NaturalBlockTheme theme;

  const _RegistryDemo({required this.theme});

  static const _source = '通常の行|:!注意の行:!|もう一行';

  @override
  Widget build(BuildContext context) {
    final registry = NaturalBlockRegistry(
      text: (context, node, scope) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Chip(
          label: TextNodeView(node: node, scope: scope),
        ),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'registry で描画を差し替える',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: NaturalBlockView(source: _source, theme: theme),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: NaturalBlockView(
                  source: _source,
                  theme: theme,
                  registry: registry,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Playground extends StatefulWidget {
  final NaturalBlockTheme theme;

  const _Playground({required this.theme});

  @override
  State<_Playground> createState() => _PlaygroundState();
}

class _PlaygroundState extends State<_Playground> {
  final _controller = TextEditingController(
    text:
        ':!*自由に書き換えて試してみよう:!:*\n'
        ':+++大きく:--標準に戻す\n'
        '左のセル^右のセル\n'
        ':@ここをタップ:@ するとSnackBarが出る',
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
            maxLines: 12,
            minLines: 4,
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
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => NaturalBlockView(
                source: _controller.text,
                theme: widget.theme,
                actions: NaturalBlockActions(
                  buildSpan: NaturalBlockImages.builder,
                  onTap: (text) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('タップされたアクション: $text')),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
