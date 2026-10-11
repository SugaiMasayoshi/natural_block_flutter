# natural_block_flutter

Flutter widgets that render the AST produced by [`natural_block`](https://github.com/SugaiMasayoshi/natural_block), a lightweight markup language for structured text layout with semantic decoration.

`natural_block` does the parsing; this package turns its `DocumentNode` / `ColumnNode` / `RowNode` / `TableNode` / `TextNode` / `TextSpanNode` / `RawNode` tree into `Column`, `Row`, `Table`, and `RichText` widgets -- with your own colors, and your own widgets substituted per node type if you want them.

## A taste of the syntax

```dart
const source = '見出し|:!危険:!普通のテキスト|左のセル^右のセル';
```

`|` starts a new vertical block, `^` starts a new horizontal cell, and a `:`-led cluster like `:!` toggles semantic decoration (color, emphasis, size) on a run of text. See the [`natural_block` README](https://github.com/SugaiMasayoshi/natural_block#readme) for the full syntax reference -- this package only concerns itself with rendering.

A row is properly written wrapped in `|`, e.g. `|A^B^C|`. Omitting the leading `|` (`A^B^C`) only works when nothing precedes the row on its own line -- otherwise the preceding line gets absorbed into the row's first cell instead of staying its own block. When in doubt, wrap the row in `|`.

### Block alignment

An alignment marker -- `<` (start), `=` (center), or `>` (end) -- placed immediately after an unescaped `|` or `^` configures how the block starting there is aligned within the space it's given:

```dart
const source = '|<品名^=数量^>価格|'
    '|<りんご^=3^>150|'
    '|<みかん^=12^>480|';
```

This renders a table-like row layout where the price column (`>`-aligned) sits flush against the right edge of its cell, regardless of how many digits each price has -- the classic motivating case being a right-aligned numeric column, such as prices in a product table.

Alignment is rendered by moving the block itself (its cross-axis alignment), not the text inside it, so it works the same whether the aligned block is a whole document, a `|`-separated line, or a `^`-separated row cell.

### Tables

Plain `^`-separated rows are rendered as a `Row` of equal-width `Expanded` cells: each row is laid out on its own, so dividing the available width evenly is the only policy that keeps columns lined up between rows. That is what makes `左^^右` push `右` to the far edge, and it is deliberately kept.

Where the available width is *unbounded* — inside a horizontally scrolling parent, or nested in another `Row` — there is no width to divide and `Expanded` cannot be used at all, so cells fall back to hugging their content. That fallback is a degradation, not an equivalent: columns stop lining up between rows and the `^<` / `^>` / `^=` markers become no-ops, since a cell exactly as wide as its content has nothing to align within. It is accepted because the alternative is the document not rendering.

Declaring a table with `~` renders a Flutter `Table` instead, with `IntrinsicColumnWidth` -- columns as wide as their content, agreed across every row:

```dart
const source = '~\n'
    '|商品^>価格\n'
    '|りんご^150\n'
    '|バナナ^98\n'
    '~';
```

Because a table is sized to its content rather than filling the width, the block that holds it can position it: `|=~...~` centers it. A one-cell table, `~注意~`, sets a single thing apart in a frame. And because its columns touch, a table needs spacing and rules that the decoration syntax cannot express -- `NaturalBlockTheme` supplies them:

* `tableCellPadding` -- space between a cell's edge and its text. Defaults to `EdgeInsets.symmetric(horizontal: 8, vertical: 4)`.
* `tableBorder` -- rules drawn around and between rows and columns. Defaults to hairlines on every edge, outer frame included: a table is the one construct with a declared beginning and end, so a frame states something the source actually says. Pass `TableBorder.symmetric(inside: ...)` for rules without the surrounding box, or `const TableBorder()` for none -- every side of that defaults to `BorderSide.none`.
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

Add `natural_block` too if you plan to register your own `NodeBuilder`s -- naming the AST node types (`TextNode`, `RowNode`, ...) requires importing the parser package directly.

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

`NaturalBlockView` takes four parameters:

* `source` (required) -- the markup text to parse and render.
* `theme` -- a [`NaturalBlockTheme`](#naturalblocktheme) controlling how tones, emphasis, and base text look. Defaults to `null`, meaning `NaturalBlockTheme.fromContext(context)`: the tones come from the surrounding `ColorScheme`, so a document reads correctly in a light theme and a dark one without being told which it is in.
* `builders` -- a [`NaturalBlockBuilders`](#naturalblockbuilders) controlling which widget renders each kind of node. Defaults to `NaturalBlockBuilders.defaults`.
* `customs` -- the [handlers](#actionable-text) an actionable run is offered to, in order, until one claims it. Defaults to `const []`, which leaves those runs styled but inert. Tappable text and images are handlers, so an app includes the ones it means: `const [NaturalBlockImages.network, links]`, where `links` is a handler of your own built on `tappableText`.

### `NaturalBlockTheme`

Maps each tone from `natural_block` (`Tone.negative`, `.positive`, `.none`) plus emphasis to a Flutter `TextStyle`:

```dart
const theme = NaturalBlockTheme(
  base: TextStyle(fontSize: 16),
  negative: TextStyle(color: Colors.red),
  positive: TextStyle(color: Colors.green),
  emphasis: TextStyle(fontWeight: FontWeight.bold),
  action: TextStyle(color: Colors.indigo, decoration: TextDecoration.underline),
);

NaturalBlockView(source: source, theme: theme);
```

Every field has a sensible default, so you only need to override the ones you want to change.

Passing a theme at all is opting out of the ambient one. A `NaturalBlockView` given no theme uses `NaturalBlockTheme.fromContext(context)`, which reads the app's `ColorScheme`; a `const NaturalBlockTheme()` built by hand uses fixed colors that cannot suit both a light and a dark surface. Reach for the constructor to change specific things, and for `fromColorScheme`/`fromContext` when you want the app's palette with a few adjustments.

Three more fields control what a size step is *worth*, since `natural_block` only reports a relative offset and never an absolute size:

* `baseFontSize` — the size to scale from when no ambient `DefaultTextStyle` supplies one. Defaults to `14`.
* `fontSizeStep` — logical pixels added per `:+` (or removed per `:-`). Defaults to `4`.
* `minFontSize` — the floor. `:-----` would otherwise be able to drive the size to zero or below, which Flutter asserts on. Defaults to `1`.

`copyWith` returns a modified copy, and `styleFor(decoration, baseSize: ...)` gives the style one run draws with -- the tone, with emphasis and actionability laid over it, at the size its `:+` and `:-` ask for. That is the whole mapping from what the source said to what is drawn, so a builder of your own can ask for it instead of reproducing the order. Every `copyWith` argument means "leave this alone" when omitted, the way Flutter's own do, and none of them can set a field *to* null -- "none" is written as a value instead (`const TableBorder()`, `const BoxDecoration()`), and a theme without stripes is what `fromColorScheme` gives you unless you ask for them.

### Raw regions

A `` ` ``-fenced region is text the parser stopped reading, so rendering only has to avoid undoing that: monospaced, whitespace and newlines exactly as written, no styling per run.

**Where it was written decides how it is drawn.** The parser makes no distinction — a region is one node either way — so `TextNodeView` answers it: a region that is a line's *only* content is that line, and is drawn as a padded code block; a region sitting among other text is a monospaced run inside the line.

```dart
const inline = '比較は`a == b`です';   // a run, no box
const block  = '`cat a | grep b`';    // a code block, boxed
```

Four theme fields control it:

* `raw` — the text style. Monospaced by default, because in a region whose whole point is exactness, indentation and the difference between `l` and `1` are part of the content.
* `rawPadding` and `rawDecoration` — the box. Pass `const BoxDecoration()` for no box; it names no colour, border or shadow, so it draws nothing.
* `rawScrollsHorizontally` — **off by default.** Wrapping is wrong for code, since a line broken in the middle reads as a different program; but turning this on puts a scroll view inside your layout, which nothing else in this package does. Turn it on where the surrounding layout can afford it.

The box is never stretched to the available width, for the same reason `ColumnNodeView` uses `Align` rather than a width-filling `SizedBox`: adding a code block must not be able to stop a document rendering.

A region also works inside a table cell, which a `|`-based marker could never have done — a cell holds lines, not blocks.

### Semantics

Actionable runs are announced to a screen reader only when something is actually wired to them: the action *style* follows the document, which said the run is actionable, but claiming interactivity when nothing is wired to them would be a promise nothing keeps. `NaturalBlockImages.network` gives every image a `semanticLabel` taken from its payload.

Tables carry no row/column semantics yet — a screen reader reads their cells as an undifferentiated stream, losing the structure the `~` declaration exists to express.

### `NaturalBlockBuilders`

Holds one builder per kind of node: `row`, `column`, `table`, `tableCell`, `text` and `raw`. This is how you customize *what* renders, not just how it looks -- give it a builder for one kind and it takes over rendering wherever that node appears, including nested inside `Column`/`Row` blocks built by the default builders.

```dart
const builders = NaturalBlockBuilders(
  text: myTextBuilder, // (TextNode node, scope) => Widget
);

NaturalBlockView(source: source, builders: builders);
```

**Which of the two extension points to reach for.** `builders` changes how a *kind of node* is drawn, everywhere it appears. `customs` decides how one *actionable run* is drawn, and declines the rest by returning null. An actionable run is not a node: `:@` is a decoration a run carries, like a tone or emphasis, so there is nothing for a builder to key on.

A builder receives the node — already typed as the kind it was registered for, so there is no cast — and a `NaturalBlockScope`: the theme, the builders, the customs, which travel together the whole way down. Recurse into a node's own children with `buildLayouts(node.children, scope)` for the blocks and rows a document holds, or `buildContents(node.children, scope)` for the lines, raw blocks and tables a block or a table cell holds. Either keeps every child on the same theme, builders and handlers. Where the tree already names one kind -- a row's cells, a table's rows -- reach for that field directly (`scope.builders.column(cell, scope)`), since there is nothing to choose.

**Neither a builder nor a handler gets a `BuildContext`.** Each is called while its parent builds, so reading an inherited widget there would bake what it read into something that cannot say what that was -- and the view, unable to know whether this document cared, would have to redraw all of it on every ambient change. For a handler it is sharper still: a span cannot read a context lazily at all, and a line keeps its spans until what they were built from changes, which can never include what a handler went and read. To read one, return a `Builder`:

```dart
text: (node, scope) => Builder(
  builder: (context) => MyLine(node, scope, MediaQuery.sizeOf(context)),
),
```

That puts the dependency in an element of its own for Flutter to track, so the document is kept and only your line redraws.

Every field defaults to the builder that draws that kind the usual way, so a set of builders names only what it changes. Those defaults (`buildRowNode`, `buildColumnNode`, `buildTableNode`, `buildTableCellNode`, `buildTextNode`, `buildRawNode`) are exported, so a builder of your own can delegate back to one.

**The node types are sealed**, so this set is the whole set: a field per kind rather than a map keyed by type, which is what keeps each builder's node type exact and makes a builder written for the wrong kind a compile error. The two entry points are narrowed the same way: `buildLayouts` takes only `LayoutNode`s and `buildContents` only `ContentNode`s, so `DocumentNode`, `TableRowNode` and the two run types — which are never drawn on their own, the view and the table and the line drawing them instead — cannot be handed to the builders at all. A table's cells skip the dispatch entirely, since `TableCellNode` is the only kind a cell can be.

The widgets the default builders use are exported as well, so a custom builder can wrap or reuse one rather than reimplementing it. `TextNodeView`, `TableNodeView` and `RawNodeView` take the node, because each reads more of one than its children; `RowNodeView(cells:)` and `ColumnNodeView(children:)` take widgets, so you can compose them out of anything. So are the types a builder signature needs: `NodeBuilder`, `NaturalBlockScope`, `RunHandler`, `RunRendering`, `widgetRun`, `OnActionTap`, and `ImageSourceKind`.

### Selectable text

Text is built with `Text.rich` rather than a bare `RichText` specifically so it takes part in text selection. Wrap a `NaturalBlockView` in a `SelectionArea` and the rendered text becomes selectable and copyable, including drags that cross cell and row boundaries:

```dart
SelectionArea(child: NaturalBlockView(source: source));
```

A directly-constructed `RichText` never registers with the selection machinery, so a `SelectionArea` around one would silently do nothing — which is why this package does not use one.

### Actionable text

Text wrapped in `:@...:@` is parsed as *actionable* -- `TextSpanNode.isAction == true`:

```dart
const source = ':@https://example.com:@ 参照';
```

This package deliberately does not call it a "link". `natural_block` only records that a run of text is tappable; the run's own `text` is the payload, and what tapping it *means* -- opening a URL, jumping to a section, resolving a mention, running a command -- is entirely the consuming app's decision. Neither the parser nor this package ever opens a URL, validates one, or otherwise interprets the text; there is no `url_launcher` dependency here and never will be.

Tapping is a handler's job, and each handler brings its own `onTap`. `tappableText` draws the run as tappable text; give it the function that says what a tap means, from a handler of your own:

```dart
void onActionTap(String text) {
  // `text` is exactly the actionable run's own text -- see the
  // convention table below for the shapes it commonly takes.
  if (text.startsWith('https://') || text.startsWith('http://')) {
    // openUrl(text); -- e.g. via url_launcher, in your own app code.
  } else {
    // Any other shape is app-defined; ignore what you don't handle.
  }
}

RunRendering? links(text, style, theme) =>
    tappableText(text, style, onTap: onActionTap);

NaturalBlockView(source: source, customs: const [links]);
```

With no handler (the default) actionable runs are still drawn in `NaturalBlockTheme.action`'s style, but they get no tap recognizer at all -- they read as tappable but aren't.

#### Drawing an actionable run yourself

An actionable run is offered to each handler in `customs` until one claims it, and a handler declines by returning `null` -- so it never has to understand every payload it might meet. Drawing a run as tappable text is what `tappableText` does, and since each handler decides what its own tap means, there is no one `onTap` for the whole view.

A handler answers with a span to put in the line and a `dispose` to release whatever that span carries:

```dart
RunRendering? mentions(text, style, theme) {
  if (!text.startsWith('@')) return null; // not mine -- offer it to the next

  final recognizer = TapGestureRecognizer()..onTap = () => openProfile(text);
  return (
    span: TextSpan(
      text: text.substring(1),
      style: style,
      recognizer: recognizer,
    ),
    dispose: recognizer.dispose,
  );
}

NaturalBlockView(
  source: source,
  customs: const [mentions, NaturalBlockImages.network, links],
);
```

**`dispose` is required, including when there is nothing to release.** It is the only guard here: a recognizer you create is yours, and the `dispose` you hand back is the only thing that will ever release it. Nothing looks inside your span to check, so forgetting leaks silently. This is the same contract Flutter hands you with `TextSpan.recognizer` -- it has no widget for inline links either ([flutter#91600](https://github.com/flutter/flutter/issues/91600) is still open) -- with a named slot that asks the question. `tappableText` is the shape to copy.

**Drawing a widget needs no `dispose` of its own**, and `widgetRun(child)` is that answer written down: everything inside a `WidgetSpan` gets the ordinary widget lifecycle, so Flutter disposes it. A `GestureDetector` in there answers a tap with no recognizer for anyone to own.

Returning a `TextSpan` rather than a widget is what keeps a long run wrapping: a `WidgetSpan` is one unbreakable box in the paragraph. Both are available, and so is anything else -- a `TextSpan` with `children:` for text built from several styled pieces that must still select as one, or a recognizer other than `TapGestureRecognizer` for a gesture other than a tap.

**Keep the list, and what it holds, stable.** A `const` list of named handlers compares equal across builds; one written out afresh inside a `build` never does, which redraws every line and loses a tap held across the redraw. A handler of your own should be a top-level function or a method of your state for the same reason.

The `style` you receive is what the span *would* have been drawn with, including everything the surrounding markup asked for, and with its `fontSize` always resolved to a concrete value -- reading it is what lets `:++` / `:--` reach content that is not text at all. `theme` comes along so you can work out what that size means relative to an unmarked run (`theme.baseFontSize`, `theme.fontSizeStep`) rather than hardcoding a reference.

A `WidgetSpan` you return is laid out with the paragraph's width but an **unbounded height**, so give its child a bounded height -- a vertically greedy one throws from inside the paragraph. Block alignment (`|^`, `=>`) reaches it for free, since that moves the whole block.

#### Images

There is no image syntax, and there is not going to be one. An image is written as an ordinary actionable span using the conventional payload `image(<url>)`, so an implementation that has never heard of images still shows `image(https://...)` — readable text — instead of failing to parse.

The word is spelled out, and `img` is deliberately **not** accepted as an alias. What the reader sees when nothing renders the payload is the whole point of the convention, and `img` is borrowed HTML jargon rather than a word; there is also no scarcity here to buy the two characters back, unlike the single-character markers. Two accepted spellings would be exactly the dialect this convention exists to prevent — so if the payload convention grows (`video(...)`, `user(...)`), the rule is simply to use the word.

`NaturalBlockImages.network` is the reference rendering for that convention:

```dart
NaturalBlockView(
  source: ':@image(https://example.com/a.png):@',
  customs: const [NaturalBlockImages.network, links],
);
```

**It is off until you pass it, deliberately.** Rendering a remote image is a network request to a third party, made simply by displaying a document. A URL carrying a per-recipient marker turns that into a read receipt; the identical request is a tracking pixel when the reader was not told. This package cannot tell those apart — it never interprets the URL — so the disclosure decision belongs to your app. It is the same reason mail clients block remote images by default.

Shipping the reference implementation anyway is the point: declining to interpret would not prevent dialects, it would guarantee them, with every app inventing its own spelling. `NaturalBlockImages.sourceOf` exposes the convention so a handler of your own can reuse it and sit in front of this one, which then takes whatever yours declined.

##### Local files

`NaturalBlockImages.network` draws network URLs and declines everything else; `NaturalBlockImages.local` draws local files and declines everything else. Include the ones you mean:

```dart
customs: const [
  NaturalBlockImages.local,
  NaturalBlockImages.network,
  links,
],
```

**Two handlers rather than one setting, because they are two decisions.** Fetching a remote image discloses to a third party that the document was opened; drawing a local one puts a file from the reader's own machine on screen under whatever text the document's author wrote. For a note synced between your own machines that is the whole point; for a document someone else wrote it is a way to show the reader their own files, and to learn which paths exist from whether they draw. Only the app knows which kind of document it renders.

Drawing a file needs `Image.file`, and so `dart:io`, which the web does not have. A conditional import settles that at build time: the web compiles a stub, so a local path declines there exactly as it does for an app that never asked for local files, and the package keeps its web support either way.

The convention does not fork — it is still `image(...)`, and only the *resolution* differs — so local file support cannot split the language.

A relative payload (`image(assets/a.png)`) is declined by both, since resolving one needs an asset bundle or a base that only the app has. Write a handler for those and put it in front; the ones behind take whatever it declines:

```dart
RunRendering? assets(text, style, theme) {
  final source = NaturalBlockImages.sourceOf(text);
  if (source == null ||
      NaturalBlockImages.kindOf(source) != ImageSourceKind.relative) {
    return null;
  }
  return widgetRun(Image.asset(source));
}

customs: const [assets, NaturalBlockImages.network, links],
```

`NaturalBlockImages.kindOf` is provided because the classification has a trap in it: `Uri.parse` reads `C:\Users\a.png` as a URI **whose scheme is `c`**, so the obvious "does it have a scheme, then it's a URL" test mistakes every Windows path for one. It reads the string only — no `dart:io`, works on every platform.

**Write Windows paths with forward slashes**: `image(C:/Users/you/a.png)`. Dart's `File` accepts them on Windows, and it avoids backslashes entirely — relevant because `\` escapes itself in the markup, so a UNC path has to be written `\\\\server` to survive as `\\server`.

Note also that letting documents name local files lets them probe for one: a path that exists draws, one that does not falls back to text. One more reason this is the app's call, and why it is a separate entry point.

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

Whichever shapes you use, **keep the payload human-readable**. That is what makes actions a safe place to extend the language at all: an implementation that does not recognise a payload still renders it as text, so `image(https://example.com/a.png)` degrades into something a person can read and act on, while an opaque identifier would degrade into nothing useful. Note that a run you draw as a `WidgetSpan` gives up part of that safety net *within your own app* too: it occupies one `￼` in the paragraph's own text, so an image copies as nothing that names it. (A `WidgetSpan` wrapping a `Text` does copy its text -- `SelectionArea` reaches into it -- so this is about widgets that hold no text, not about `WidgetSpan` itself.)

Resolving any of this -- looking up `#name`, deciding what `@name` refers to, or anything else -- is entirely the app's responsibility; `natural_block` and `natural_block_flutter` only carry the text through.

## Additional information

* **Source Code & Issues:** [GitHub repository](https://github.com/SugaiMasayoshi/natural_block_flutter).
* **Parsing details, decoration rules, and syntax reference:** see the [`natural_block` package](https://github.com/SugaiMasayoshi/natural_block).
* **Contributions:** pull requests are welcome. Please include widget tests for new builders or theme behavior.
