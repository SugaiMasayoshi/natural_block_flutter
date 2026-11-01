# natural_block_flutter

Flutter widgets that render [natural_block](https://github.com/SugaiMasayoshi/natural_block),
a lightweight markup language that leaves ordinary prose alone. Blocks,
rows, tables, alignment, semantic decoration and code become `Column`,
`Row`, `Table` and selectable `Text.rich` widgets, styled from your app's
color scheme.

See the [natural_block README](https://github.com/SugaiMasayoshi/natural_block#readme)
for the syntax.

## Getting started

```
flutter pub add natural_block_flutter
```

`natural_block` is re-exported, so one import also names the node types and
`SpanDecoration`.

## Usage

```dart
import 'package:flutter/material.dart';
import 'package:natural_block_flutter/natural_block_flutter.dart';

class Example extends StatelessWidget {
  const Example({super.key});

  @override
  Widget build(BuildContext context) {
    return const NaturalBlockView(
      source: '|=:++*見出し|:!在庫切れ:! です|<品名^>価格',
    );
  }
}
```

`NaturalBlockView` takes:

- `source` -- the markup to render.
- `theme` -- a `NaturalBlockTheme`. Defaults to
  `NaturalBlockTheme.fromContext(context)`, which follows the app's
  `ColorScheme` and text size in light and dark themes.
- `builders` -- a `NaturalBlockBuilders` that replaces the widget for a kind
  of node.
- `customs` -- handlers for custom runs (`:@...:@`). Empty by default, so
  custom runs are styled but inert.

`customs` and `builders` must be `const`; the analyzer warns when they are
not. Write handlers and builders as top-level functions.

Wrap the view in a `SelectionArea` to make the text selectable across
blocks and cells.

## Theme

```dart
NaturalBlockView(
  source: source,
  theme: NaturalBlockTheme.fromContext(context, striped: true),
);
```

`fromContext` and `fromColorScheme` derive colors from the app; `striped:
true` bands table rows instead of ruling them. Change anything else with
`copyWith`, or build a theme by hand with the constructor:

| Field | Controls |
|---|---|
| `base`, `negative`, `positive`, `emphasis`, `custom` | Text styles for each decoration |
| `baseFontSize`, `fontSizeStep`, `minFontSize` | What a `:+` / `:-` step is worth |
| `tableCellPadding`, `tableBorder`, `tableStripe` | Tables |
| `raw`, `rawPadding`, `rawDecoration`, `rawScrollsHorizontally` | Code regions |

`styleFor(decoration, baseSize: ...)` gives the style a run is drawn with.
To turn a border or box off, pass `const TableBorder()` or
`const BoxDecoration()`.

## Custom runs

The parser only marks a run as custom; its text is the payload, and your
handlers decide what it means. Each run is offered to the handlers in
`customs` in order, and a handler declines by returning `null`.

### Tappable text

```dart
RunRendering? links(CustomRun run) {
  if (!run.text.startsWith('https://')) return null;
  return tappableText(
    run,
    onTap: (context) {
      // e.g. launchUrl(Uri.parse(run.text)) with url_launcher.
    },
  );
}

NaturalBlockView(source: source, customs: const [links]);
```

`onTap` receives the line's `BuildContext` at the time of the tap.

### Your own spans

A handler returns the span to put in the line and a `dispose` that releases
what the span holds:

```dart
RunRendering? mentions(CustomRun run) {
  if (!run.text.startsWith('@')) return null;

  final recognizer = TapGestureRecognizer()
    ..onTap = () => run.withContext((context) => openProfile(context, run.text));
  return (
    span: TextSpan(text: run.text, style: run.style, recognizer: recognizer),
    dispose: recognizer.dispose,
  );
}
```

- `dispose` is required. Release every recognizer you create there, and pass
  `() {}` when there is nothing to release.
- `widgetRun(child)` draws a widget in the line, centred on the text. Give
  the child a bounded height.
- `run.style` is the style the run would have been drawn with;
  `run.decoration` is what the source said about it.
- `run.withContext` gives the line's `BuildContext` for later, such as a
  tap. Calling it while drawing asserts.

### Images

An image is written as a custom run with the payload `image(<url>)`:

```dart
NaturalBlockView(
  source: ':@image(https://example.com/a.png):@',
  customs: const [NaturalBlockImages.network],
);
```

- `NaturalBlockImages.network` draws network URLs. It is off until
  included, because drawing a remote image tells a third party the document
  was opened.
- `NaturalBlockImages.local` draws local files, and declines on the web.
  Include it only for documents you trust to name files on the reader's
  machine.
- Write Windows paths with forward slashes: `image(C:/Users/you/a.png)`.
- Relative paths are declined by both. Put a handler of your own in front
  to resolve them:

  ```dart
  RunRendering? assets(CustomRun run) {
    final source = NaturalBlockImages.sourceOf(run.text);
    if (source == null ||
        NaturalBlockImages.kindOf(source) != ImageSourceKind.relative) {
      return null;
    }
    return widgetRun(Image.asset(source));
  }
  ```

- `NaturalBlockImages.scaleOf(run)` follows the run's `:+` / `:-` steps.

### A payload convention (non-normative)

| Text | Meaning |
|---|---|
| `https://...` | an external URL |
| `#name` | a target in the same document |
| `path#name` | a target in another document |
| `@name` | a mention |
| `image(<url>)` | an image |

Keep payloads human-readable: an app that does not recognise one still shows
it as text.

## Builders

`NaturalBlockBuilders` has one builder per kind of node: `row`, `column`,
`table`, `tableCell`, `text` and `raw`. Each defaults to the one that draws
that kind as usual, so you name only what you change:

```dart
Widget spacedText(TextNode node, NaturalBlockScope scope) => Padding(
  padding: const EdgeInsets.only(bottom: 8),
  child: buildTextNode(node, scope),
);

const builders = NaturalBlockBuilders(text: spacedText);
```

- The defaults (`buildRowNode`, `buildColumnNode`, `buildTableNode`,
  `buildTableCellNode`, `buildTextNode`, `buildRawNode`) and their widgets
  (`RowNodeView`, `ColumnNodeView`, `TableNodeView`, `TextNodeView`,
  `RawNodeView`) are exported to delegate to or reuse.
- Recurse into children with `buildLayouts(node.children, scope)` or
  `buildContents(node.children, scope)`, so they keep the same theme,
  builders and handlers.
- A builder gets no `BuildContext`. To read an inherited widget, return a
  `Builder`, so Flutter redraws only that part when it changes.

## Limitations

- Where the width is unbounded, such as in a horizontal scroll view, row
  cells shrink to their content: columns no longer line up and alignment
  markers have no effect.
- Tables have no row and column semantics for screen readers yet.
- A run drawn as a widget copies as nothing when selected, unless the
  widget holds text.

## Additional information

- Bugs and feature requests:
  [GitHub issues](https://github.com/SugaiMasayoshi/natural_block_flutter/issues).
- Why it is built this way: [doc/design.md](doc/design.md) (in Japanese).
