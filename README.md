# natural_block_flutter

Flutter widgets that render the AST produced by [`natural_block`](https://github.com/SugaiMasayoshi/natural_block), a lightweight markup language for structured text layout with semantic decoration.

`natural_block` does the parsing; this package turns its `DocumentNode` / `ColumnNode` / `RowNode` / `TableNode` / `TextNode` / `TextSpanNode` tree into `Column`, `Row`, `Table`, and `RichText` widgets -- with your own colors, and your own widgets substituted per node type if you want them.

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

### Tables

Plain `=`-separated rows are rendered as a `Row` of equal-width `Expanded` cells: each row is laid out on its own, so dividing the available width evenly is the only policy that keeps columns lined up between rows. That is what makes `左==右` push `右` to the far edge, and it is deliberately kept.

Declaring a table with `|~` renders a Flutter `Table` instead, with `IntrinsicColumnWidth` -- columns as wide as their content, agreed across every row:

```dart
const source = '|~商品=>価格|'
    'りんご=150|'
    'バナナ=98|';
```

Because a table is sized to its content rather than filling the width, it can be positioned: `|~^` centers it. And because its columns touch, a table needs spacing and rules that the decoration syntax cannot express -- `NaturalBlockTheme` supplies them:

* `tableCellPadding` -- space between a cell's edge and its text. Defaults to `EdgeInsets.symmetric(horizontal: 8, vertical: 4)`.
* `tableBorder` -- rules drawn around and between rows and columns. Defaults to hairlines on every edge, outer frame included: a table is the one construct with a declared beginning and end, so a frame states something the source actually says. Pass `TableBorder.symmetric(inside: ...)` for rules without the surrounding box, or `null` for none.
* `tableStripe` -- a background painted on every other row, starting with the second. Off by default.

To band a table's rows instead of ruling them, use `NaturalBlockTheme.fromColorScheme(scheme, striped: true)` (or `fromContext(context, striped: true)`), which sets the band and drops the horizontal rules, keeping the vertical ones and the frame:

```dart
NaturalBlockView(
  source: source,
  theme: NaturalBlockTheme.fromContext(context, striped: true),
);
```

Striping is offered there rather than on the default constructor because it is only *safe* there: a band has to be darker than the surface in a light theme and lighter in a dark one, so no single constant can serve both. A fixed translucent black moves a light surface by about ten steps per channel but a dark one by one — invisible. Derived from the scheme's `surfaceContainerHigh`, it reads correctly either way.

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

`NaturalBlockView` takes five parameters:

* `source` (required) -- the markup text to parse and render.
* `theme` -- a [`NaturalBlockTheme`](#naturalblocktheme) controlling how semantic colors, emphasis, and base text look. Defaults to `const NaturalBlockTheme()`.
* `registry` -- a [`NaturalBlockRegistry`](#naturalblockregistry) controlling which widget renders each node type. Defaults to `NaturalBlockRegistry.defaults`.
* `onActionTap` -- called with a span's own text when an [actionable span](#actionable-text) is tapped. Defaults to `null` (actionable spans render styled but aren't tappable).
* `onActionBuild` -- renders an actionable span as something other than styled text (an image, a chip). Defaults to `null`. See [Rendering an actionable span yourself](#rendering-an-actionable-span-yourself).

### `NaturalBlockTheme`

Maps each semantic color from `natural_block` (`SemanticColor.danger`, `.success`, `.info`, `.none`) plus emphasis to a Flutter `TextStyle`:

```dart
const theme = NaturalBlockTheme(
  base: TextStyle(fontSize: 16),
  danger: TextStyle(color: Colors.red),
  success: TextStyle(color: Colors.green),
  info: TextStyle(color: Colors.blue),
  emphasis: TextStyle(fontWeight: FontWeight.bold),
  action: TextStyle(color: Colors.indigo, decoration: TextDecoration.underline),
);

NaturalBlockView(source: source, theme: theme);
```

Every field has a sensible default, so you only need to override the ones you want to change.

### `NaturalBlockRegistry`

Maps each AST node type to the function that builds a widget for it. This is how you customize *what* renders, not just how it looks -- register your own builder for a node type and it takes over rendering wherever that node appears, including nested inside `Column`/`Row` blocks built by the default registry.

```dart
final registry = NaturalBlockRegistry.defaults.register(
  TextNode,
  (context, node, theme, registry, actions) =>
      MyCustomTextWidget(node: node as TextNode, theme: theme),
);

NaturalBlockView(source: source, registry: registry);
```

A `NodeBuilder` receives the node to render, the ambient theme, the registry itself, and a `NaturalBlockActions` to forward to any actionable spans inside it (so it can recurse into a node's own children, e.g. a `ColumnNode` builder rendering each of its children via `registry.buildAll`), and returns the widget for that node directly.

Use `NaturalBlockRegistry.empty()` to start from nothing and register only the node types you care about, or `registerAll` to register several builders at once. The default builders (`buildRowNode`, `buildColumnNode`, `buildTableNode`, `buildTextNode`) are exported too, so a custom builder can delegate back to the default for the cases it doesn't want to change.

### Actionable text

Text wrapped in `:@...:@` is parsed as *actionable* -- `TextSpanNode.isAction == true`:

```dart
const source = ':@https://example.com:@ 参照';
```

This package deliberately does not call it a "link". `natural_block` only records that a run of text is tappable; the run's own `text` is the payload, and what tapping it *means* -- opening a URL, jumping to a section, resolving a mention, running a command -- is entirely the consuming app's decision. Neither the parser nor this package ever opens a URL, validates one, or otherwise interprets the text; there is no `url_launcher` dependency here and never will be.

Give `NaturalBlockView` an `onActionTap` callback to find out when an actionable span is tapped:

```dart
NaturalBlockView(
  source: source,
  onActionTap: (text) {
    // `text` is exactly the actionable span's own text -- see the
    // convention table below for the shapes it commonly takes.
    if (text.startsWith('https://') || text.startsWith('http://')) {
      // openUrl(text); -- e.g. via url_launcher, in your own app code.
    } else {
      // Any other shape is app-defined; ignore what you don't handle.
    }
  },
);
```

Leaving `onActionTap` unset (the default, `null`) still renders actionable spans with `NaturalBlockTheme.action`'s style, but they get no tap recognizer at all -- they read as tappable but aren't.

#### Rendering an actionable span yourself

`onActionBuild` replaces an actionable span's rendering entirely — text, style and gestures. It is consulted for every actionable span, and returning `null` for one leaves it to the default styled text, so a builder never has to understand every payload it might meet:

```dart
NaturalBlockView(
  source: source,
  onActionBuild: (context, text, style) {
    if (text.startsWith('@')) return TextSpan(text: text.substring(1), style: style);
    return null; // not mine -- render it as usual
  },
);
```

The `style` you receive is what the span *would* have been drawn with, including everything the surrounding markup asked for. Reading `style.fontSize` is what lets `:++` / `:--` reach content that is not text at all. Block alignment (`|^`, `=>`) reaches it for free, since that moves the whole block.

#### Images

There is no image syntax, and there is not going to be one. An image is written as an ordinary actionable span using the conventional payload `image(<url>)`, so an implementation that has never heard of images still shows `image(https://...)` — readable text — instead of failing to parse.

The word is spelled out, and `img` is deliberately **not** accepted as an alias. What the reader sees when nothing renders the payload is the whole point of the convention, and `img` is borrowed HTML jargon rather than a word; there is also no scarcity here to buy the two characters back, unlike the single-character markers. Two accepted spellings would be exactly the dialect this convention exists to prevent — so if the payload convention grows (`video(...)`, `user(...)`), the rule is simply to use the word.

`NaturalBlockImages.builder` is the reference rendering for that convention:

```dart
NaturalBlockView(
  source: ':@image(https://example.com/a.png):@',
  onActionBuild: NaturalBlockImages.builder,
);
```

**It is off until you pass it, deliberately.** Rendering a remote image is a network request to a third party, made simply by displaying a document. A URL carrying a per-recipient marker turns that into a read receipt; the identical request is a tracking pixel when the reader was not told. This package cannot tell those apart — it never interprets the URL — so the disclosure decision belongs to your app. It is the same reason mail clients block remote images by default.

Shipping the reference implementation anyway is the point: declining to interpret would not prevent dialects, it would guarantee them, with every app inventing its own spelling. `NaturalBlockImages.urlOf` exposes the convention so your own builder can reuse it and fall back to `NaturalBlockImages.builder` for the rest.

##### Local files

`NaturalBlockImages.builder` renders network URLs and declines everything else. Drawing a local file needs `Image.file`, and so `dart:io`, which does not exist on the web — taking that on here would cost this package its web support for a capability only some apps want. Supply it in your own builder instead:

```dart
onActionBuild: (context, text, style) {
  final source = NaturalBlockImages.urlOf(text);
  if (source != null &&
      NaturalBlockImages.kindOf(source) == ImageSourceKind.file) {
    return WidgetSpan(child: Image.file(File(source)));
  }
  return NaturalBlockImages.builder(context, text, style);
},
```

The convention does not fork when you do this — it is still `image(...)`, and only the *resolution* differs — so unlike a new syntax, local file support cannot split the language.

`NaturalBlockImages.kindOf` is provided because the classification has a trap in it: `Uri.parse` reads `C:\Users\a.png` as a URI **whose scheme is `c`**, so the obvious "does it have a scheme, then it's a URL" test mistakes every Windows path for one. It reads the string only — no `dart:io`, works on every platform.

**Write Windows paths with forward slashes**: `image(C:/Users/you/a.png)`. Dart's `File` accepts them on Windows, and it avoids backslashes entirely — relevant because `\` escapes itself in the markup, so a UNC path has to be written `\\\\server` to survive as `\\server`.

Note also that letting documents name local files lets them probe for one: a path that exists draws, one that does not falls back to text. One more reason this is the app's call.

#### A convention for what the text means (non-normative)

`natural_block` places no constraint on an actionable span's text. The following convention is not enforced by the parser or this package, but mirrors URI/fragment conventions most readers and authors already know, so it's a reasonable default if you don't already have one:

| text | meaning |
|---|---|
| `https://...` | external URL -- open it |
| `#name` | a target inside the same document |
| `path#name` | a target in another document |
| `@name` | a mention |
| `image(<url>)` | an image -- see [Images](#images) |
| anything else | app-defined |

Whichever shapes you use, **keep the payload human-readable**. That is what makes actions a safe place to extend the language at all: an implementation that does not recognise a payload still renders it as text, so `image(https://example.com/a.png)` degrades into something a person can read and act on, while an opaque identifier would degrade into nothing useful. Note that a span you replace via `onActionBuild` gives up that safety net *within your own app* too -- a `WidgetSpan` copies as `￼`, not as the text that named it.

Resolving any of this -- looking up `#name`, deciding what `@name` refers to, or anything else -- is entirely the app's responsibility; `natural_block` and `natural_block_flutter` only carry the text through.

## Additional information

* **Source Code & Issues:** [GitHub repository](https://github.com/SugaiMasayoshi/natural_block_flutter).
* **Parsing details, decoration rules, and syntax reference:** see the [`natural_block` package](https://github.com/SugaiMasayoshi/natural_block).
* **Contributions:** pull requests are welcome. Please include widget tests for new builders or theme behavior.
