# natural_block_flutter

Flutter widgets that render the AST produced by [`natural_block`](https://github.com/SugaiMasayoshi/natural_block), a lightweight markup language for structured text layout with semantic decoration.

`natural_block` does the parsing; this package turns its `ColumnNode` / `RowNode` / `TextNode` / `TextSpanNode` tree into `Column`, `Row`, and `RichText` widgets -- with your own colors, and your own widgets substituted per node type if you want them.

## A taste of the syntax

```dart
const source = '見出し|:!危険:!普通のテキスト|左のセル=右のセル';
```

`|` starts a new vertical block, `=` starts a new horizontal cell, and a `:`-led cluster like `:!` toggles semantic decoration (color, emphasis, size) on a run of text. See the [`natural_block` README](https://github.com/SugaiMasayoshi/natural_block#readme) for the full syntax reference -- this package only concerns itself with rendering.

A row is properly written wrapped in `|`, e.g. `|A=B=C|`. Omitting the leading `|` (`A=B=C`) only works when nothing precedes the row on its own line -- otherwise the preceding line gets absorbed into the row's first cell instead of staying its own block. When in doubt, wrap the row in `|`.

### Block alignment

An alignment marker -- `<` (start), `^` (center), or `>` (end) -- placed immediately after an unescaped `|` or `=` configures how the block starting there is aligned within the space it's given:

```dart
const source = '|<品名=^数量=>価格|'
    '|<りんご=^3=>150|'
    '|<みかん=^12=>480|';
```

This renders a table-like row layout where the price column (`>`-aligned) sits flush against the right edge of its cell, regardless of how many digits each price has -- the classic motivating case being a right-aligned numeric column, such as prices in a product table.

Alignment is rendered by moving the block itself (its cross-axis alignment), not the text inside it, so it works the same whether the aligned block is a whole document, a `|`-separated line, or a `=`-separated row cell.

## Getting started

```yaml
dependencies:
  natural_block_flutter: ^0.0.1
```

## Usage

### `NaturalBlockView`

The main widget. Give it a `source` string; it parses and renders it.

```dart
import 'package:flutter/material.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

class Example extends StatelessWidget {
  const Example({super.key});

  @override
  Widget build(BuildContext context) {
    return const NaturalBlockView(
      source: ':!Important Notice:!|Normal text',
    );
  }
}
```

`NaturalBlockView` takes three parameters:

* `source` (required) -- the markup text to parse and render.
* `theme` -- a [`NaturalBlockTheme`](#naturalblocktheme) controlling how semantic colors, emphasis, and base text look. Defaults to `const NaturalBlockTheme()`.
* `registry` -- a [`NaturalBlockRegistry`](#naturalblockregistry) controlling which widget renders each node type. Defaults to `NaturalBlockRegistry.defaults`.

### `NaturalBlockTheme`

Maps each semantic color from `natural_block` (`SemanticColor.danger`, `.success`, `.info`, `.none`) plus emphasis to a Flutter `TextStyle`:

```dart
const theme = NaturalBlockTheme(
  base: TextStyle(fontSize: 16),
  danger: TextStyle(color: Colors.red),
  success: TextStyle(color: Colors.green),
  info: TextStyle(color: Colors.blue),
  emphasis: TextStyle(fontWeight: FontWeight.bold),
);

NaturalBlockView(source: source, theme: theme);
```

Every field has a sensible default, so you only need to override the ones you want to change.

### `NaturalBlockRegistry`

Maps each AST node type to the function that builds a widget for it. This is how you customize *what* renders, not just how it looks -- register your own builder for a node type and it takes over rendering wherever that node appears, including nested inside `Column`/`Row` blocks built by the default registry.

```dart
final registry = NaturalBlockRegistry.defaults.register(
  TextNode,
  (context, node, theme, registry) =>
      MyCustomTextWidget(node: node as TextNode, theme: theme),
);

NaturalBlockView(source: source, registry: registry);
```

A `NodeBuilder` receives the node to render, the ambient theme, and the registry itself (so it can recurse into a node's own children, e.g. a `ColumnNode` builder rendering each of its children via `registry.buildAll`), and returns the widget for that node directly.

Use `NaturalBlockRegistry.empty()` to start from nothing and register only the node types you care about, or `registerAll` to register several builders at once. The default builders (`buildRowNode`, `buildColumnNode`, `buildTextNode`) are exported too, so a custom builder can delegate back to the default for the cases it doesn't want to change.

## Additional information

* **Source Code & Issues:** [GitHub repository](https://github.com/SugaiMasayoshi/natural_block_flutter).
* **Parsing details, decoration rules, and syntax reference:** see the [`natural_block` package](https://github.com/SugaiMasayoshi/natural_block).
* **Contributions:** pull requests are welcome. Please include widget tests for new builders or theme behavior.
