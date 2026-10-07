## 0.0.1

Initial release.

### Rendering

- `NaturalBlockView` parses a `natural_block` `source` string and renders it.
  It parses once per source, not once per build: the tree owes nothing to the
  `BuildContext`, so an ancestor rebuilding -- a theme change, an animating
  parent, a scroll -- reuses it, and only a new `source` re-parses.
- It keeps the drawn tree too, and hands back the very same widget object
  when nothing it was drawn from has changed. That is the one thing Flutter
  watches for: `updateChild` stops at a child whose widget has not changed,
  so the whole document is skipped rather than rebuilt. `const` is the
  framework's own version of this and cannot apply here, since a parsed
  document is not a compile-time value. The comparison deliberately leaves
  `onTap` out and reads it at tap time instead: a caller writes it as a
  closure in their own `build`, and Dart never considers two closures equal,
  so comparing it would miss every time. Measured on a debug build, an
  ancestor rebuild of a 50-paragraph document went from 12.2ms to 7.0ms.
- `TextNodeView` draws a line's styled runs, built with `Text.rich` so the
  result takes part in text selection: wrap a view in a `SelectionArea` and
  the text is selectable and copyable across cell and row boundaries.
- A line's spans and the recognizers they carry are one object, built once
  and kept until what they are made of changes. This is a correctness
  measure, not a speed one -- it does not make a rebuild faster. A
  recognizer that has taken a pointer down owns an entry in the gesture
  arena, and replacing it mid-gesture throws that entry away: the tap then
  vanishes with no error anywhere, and a test that calls `onTap` directly
  cannot see it, because that bypasses the arena. Flutter's own
  `TextSpan.recognizer` sample holds its recognizer in `State` for the same
  reason and never rebuilds it. Ambient changes that do not reach the spans
  -- a `DefaultTextStyle` size the theme's `base` overrides -- are not a
  reason to replace one either, so both `didChangeDependencies` and
  `didUpdateWidget` ask the same question in the same place.
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
  the author wrote. Cells still go through the builders, so a caller's own
  `ColumnNode` builder applies inside a table.

- The mapping from `HorizontalAlign` to Flutter layout lives in one
  extension. Both views used to hold a copy of it, one written as a `switch`
  statement and one as a switch expression, which made the duplication easy
  to miss.
- Every run of a line starts from one expression: the ambient style with the
  theme's `base` merged over it. The root span and the baseline a `:+`
  counts from were once computed separately, and a theme whose `base` named
  a size made `:+` render smaller than the text beside it.

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
  dark one, so no single constant can serve both. The raw block's box is
  derived there for the same reason: a fixed translucent black moves a light
  surface by about ten steps per channel and a dark one by one, which is
  invisible.
- A view given no theme uses `fromContext`, so a document reads correctly in
  a light theme and a dark one without being told which it is in. Passing a
  theme is opting out of that.
- "None" is written as a value, not as null: `const TableBorder()` has
  `BorderSide.none` on every side and measures the same as no border at all,
  and a `const BoxDecoration()` names no colour, border or shadow. That is
  what lets `copyWith` mean "leave this alone" for every omitted argument,
  the way Flutter's own `copyWith` methods do, with no sentinel standing in
  for "not passed". `tableStripe` stays nullable, because `Color` has no
  "none" of its own and a transparent one is still a fill -- it would put a
  decoration on every other row of every table.
- `copyWith`, `styleFor`, `==` / `hashCode`.

### Customization

- `NaturalBlockBuilders` holds one builder per kind of node -- `row`,
  `column`, `table`, `tableCell`, `text`, `raw` -- each defaulting to the one
  that draws that kind the usual way, so a value names only what it changes.
  The node types are sealed, so the set is closed and can be named: the
  builder's node type stays exact, nothing is cast on the way in, and a
  builder written for the wrong kind does not compile. It replaced a
  `Type`-keyed map, which modelled an openness the AST does not have and
  needed a fallback for types that cannot occur.
- Default builders (`buildRowNode`, `buildColumnNode`, `buildTableNode`,
  `buildTableCellNode`, `buildTextNode`, `buildRawNode`) are exported so a
  builder of your own can delegate back. Naming one that way also keeps
  `NaturalBlockBuilders` comparable: a builder written as a closure literal
  is never equal to another, which costs a redraw but never correctness.
- Choosing between the fields is `buildLayouts` / `buildContents`' job, and
  they are the only places the tree says merely that one of several kinds is
  there. Each switches over a sealed set small enough to be exhaustive, so
  the nodes that are never drawn on their own -- the document, a table's
  rows, the runs -- cannot be handed to a builder at all. Where the tree
  already names one kind, as a table's cells do, there is nothing to choose
  and the field is called directly. They are also how a builder of your own
  recurses into a node's children, which keeps those children on the same
  theme, builders and actions.
- A builder receives the node and one `NaturalBlockScope`, which carries the
  theme, the builders and the actions. The three travel together the whole
  way down and no level swaps one of them for its children, so they are one
  value rather than three parameters repeated at every level. The
  `BuildContext` stays outside it: it is the one thing that really does
  differ per level, and keeping it out is what lets the default builders stay
  `const`.

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

- `NaturalBlockActions` carries both of these, and `NaturalBlockView` takes
  it as one `actions` parameter, like `theme` and `builders`. It used to take
  the two callbacks flat and bundle them internally, which left one thing
  with two names on the way in.
- `onTap` reports a tap with the run's own text. Nothing here ever
  interprets that text — no URL is opened, and there is no `url_launcher`
  dependency.
- `buildSpan` replaces a run's rendering entirely; returning `null` for
  a payload leaves it to the default, so an unrecognized one still reads as
  text.
- `NaturalBlockImages.builder` is the reference rendering for the
  conventional `image(<url>)` payload, off until passed: drawing a remote
  image is a network request to a third party made by displaying a
  document, which is a disclosure decision belonging to the app.
  `NaturalBlockImages.kindOf` classifies a payload as network, file, or
  relative without needing `dart:io`.
- `NaturalBlockImages.withLocalFiles` draws local files as well. A second
  entry point rather than a setting on the first, because the two are
  different decisions: a remote image tells a third party the document was
  opened, a local one puts the reader's own file on screen under someone
  else's text. A note synced between your own machines wants it; a document
  written by someone else may not. `dart:io` stays off the web through a
  conditional import, so a local path there declines as it always did.
- A run is announced to a screen reader only when something is wired to it.
