## 0.0.1

Initial release.

### Rendering

- `NaturalBlockView` parses a `natural_block` `source` string and renders it.
  It parses once per source, not once per build: the tree owes nothing to the
  `BuildContext`, so an ancestor rebuilding -- a theme change, an animating
  parent, a scroll -- reuses it, and only a new `source` re-parses.
- `TextNodeView` draws a line's styled runs, built with `Text.rich` so the
  result takes part in text selection: wrap a view in a `SelectionArea` and
  the text is selectable and copyable across cell and row boundaries.
- `ColumnNodeView` stacks blocks and honours `HorizontalAlign`. Unstated and
  `HorizontalAlign.start` both draw at the start, but are kept apart so a theme
  can style unaligned blocks without overriding one that asked. A non-start
  block is wrapped in `Align` rather than a width-filling box, so adding an
  alignment marker can never make a document stop rendering where the
  available width is unbounded.
- `RowNodeView` gives each cell of a row an equal share of the width, which
  is what keeps columns lined up between rows. Where the width is unbounded
  it falls back to shrink-wrapped cells — a degradation, since columns then
  stop lining up and alignment markers become no-ops, but better than not
  rendering.
- `TableNodeView` renders a `TableNode` with `IntrinsicColumnWidth`, so a
  declared table's columns are as wide as their content and agree across
  every row. It also does the two things the tree deliberately leaves undone:
  it squares short rows off to the table's width (Flutter's `TableRow`
  requires every row to hold the same number of children) and resolves each
  cell's alignment against its column (`cell.align ?? table.columns[i]`).
  Both are questions about drawing, asked of a tree that records only what
  the author wrote. Cells still go through the registry, so a caller's own
  `ColumnNode` builder applies inside a table.

### Theming

- `NaturalBlockTheme` maps tones, emphasis, and actionability to
  `TextStyle`s, and controls what a size step is worth (`baseFontSize`,
  `fontSizeStep`, `minFontSize`).
- Table appearance: `tableCellPadding`, `tableBorder` (a full frame by
  default), `tableStripe` (off by default).
- `fromColorScheme` / `fromContext` derive a theme that adapts to
  brightness, with `striped: true` banding a table's rows instead of ruling
  them. Striping lives there rather than on the default constructor because
  a band must be darker than the surface in a light theme and lighter in a
  dark one, so no single constant can serve both.
- `copyWith`, `styleFor`, `==` / `hashCode`.

### Customization

- `NaturalBlockRegistry` maps node types to the builder that renders them,
  with `register` / `registerAll`. Lookup is by exact `runtimeType`, and a
  node with no builder renders nothing with a debug-mode warning.
- Default builders (`buildRowNode`, `buildColumnNode`, `buildTableNode`,
  `buildTextNode`) are exported so a custom builder can delegate back.
- A builder receives the node and one `NaturalBlockScope`, which carries the
  theme, the registry and the actions. The three travel together the whole
  way down and no level swaps one of them for its children, so they are one
  value rather than three parameters repeated at every level. `buildAll`
  lives on the scope for the same reason. The `BuildContext` stays outside
  it: it is the one thing that really does differ per level, and keeping it
  out is what lets the default builder map stay `const`.

### Raw regions

- A `` ` ``-fenced region renders monospaced, with whitespace and newlines
  exactly as written. Where it was written decides how it is drawn: a region
  that is a line's only content is a padded code block, one among other text
  is a monospaced run.
- `raw`, `rawPadding` and `rawDecoration` style it.
- `rawScrollsHorizontally` (off by default) makes long lines scroll
  rather than wrap. Wrapping is wrong for code, but turning this on puts a
  scroll view inside the caller's layout, which nothing else here does.

### Actionable runs

- `onActionTap` reports a tap with the run's own text. Nothing here ever
  interprets that text — no URL is opened, and there is no `url_launcher`
  dependency.
- `onActionBuild` replaces a run's rendering entirely; returning `null` for
  a payload leaves it to the default, so an unrecognized one still reads as
  text.
- `NaturalBlockImages.builder` is the reference rendering for the
  conventional `image(<url>)` payload, off until passed: drawing a remote
  image is a network request to a third party made by displaying a
  document, which is a disclosure decision belonging to the app.
  `NaturalBlockImages.kindOf` classifies a payload as network, file, or
  relative without needing `dart:io`.
- A run is announced to a screen reader only when something is wired to it.
