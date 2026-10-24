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
  document is not a compile-time value. Measured on a debug build, an
  ancestor rebuild of a 50-paragraph document went from 12.2ms to 7.0ms.
- Every list whose length is known before it is filled is built with
  `List.generate` rather than a collection-for. A collection-for and a
  hand-written `add` measure the same, because both grow a list and pay for
  the reallocation; pre-sizing is what costs less. Compiled ahead of time and
  measured on list building alone, a thousand elements cost 22.5us one way
  and 3.9us the other. A loop stays a loop where no list comes out of it --
  asking the handlers in order, releasing what a line made.
- Turning a line into spans hands back the spans and, separately, whatever
  needs releasing. Nothing ever asks which `dispose` belongs to which span,
  so pairing them cost a record per run that was built, destructured, and
  then held for the life of the line -- and a line of ordinary text held one
  per run with nothing in it. Only a run a handler claims adds anything now,
  so such a line has nothing to release at all. Measured in one session
  against the shape it replaced: 156ns per run became 143ns for a line of a
  thousand runs, and 180ns became 129ns for a line of twenty.
- What it compares is the `NaturalBlockScope` it drew with, and the document
  -- not a second list of the same fields kept for comparing. That second
  list is a place for a field to reach the drawing and not the comparison,
  and then a change never redraws; `NaturalBlockScope` now carries value
  equality so there is one list instead of two. `customs` is `const`,
  so the list compares as the same one.
- `TextNodeView` draws a line's styled runs, built with `Text.rich` so the
  result takes part in text selection: wrap a view in a `SelectionArea` and
  the text is selectable and copyable across cell and row boundaries.
- A line's spans are built once and kept in its `State` until what they are
  made of changes. This is a correctness measure, not a speed one -- it does
  not make a rebuild faster. A recognizer that has taken a pointer down owns
  an entry in the gesture arena, and replacing it mid-gesture throws that
  entry away: the tap then vanishes with no error anywhere, and a test that
  calls `onTap` directly cannot see it, because that bypasses the arena.
  Flutter's own `TextSpan.recognizer` sample holds its recognizer in `State`
  for the same reason and never rebuilds it. Ambient changes that do not
  reach the spans -- a `DefaultTextStyle` size the theme's `base` overrides
  -- are not a reason to replace one either, so the question is asked once
  in `build`, which runs after both `didUpdateWidget` and
  `didChangeDependencies`.
- The spans lived in an `InlineSpans` object of their own for a while. That
  existed because the state was two parallel fields -- the spans and the
  recognizers -- whose correspondence was kept only by the order they were
  written in, and bundling them made replacing one without the other
  impossible. Once a handler began answering with what to release rather
  than the package finding it, the spans became a projection of those
  answers and could no longer disagree with them, so the object was holding
  one widget's state and a relayed `dispose`. It went back into the `State`
  that is for exactly that.
- `ColumnNodeView` stacks blocks and honours `HorizontalAlign`. Unstated and
  `HorizontalAlign.start` both draw at the start; what keeps them apart is a
  table, where a cell that stated nothing is drawn with its column instead.
  A non-start block is wrapped in `Align` rather than a width-filling box, so
  adding an alignment marker can never make a document stop rendering where
  the available width is unbounded.
- `RowNodeView` gives each cell of a row an equal share of the width, which
  is what keeps columns lined up between rows. Where the width is unbounded
  it falls back to shrink-wrapped cells — a degradation, since columns then
  stop lining up and alignment markers become no-ops, but better than not
  rendering.
- It takes the cells as widgets, not a `RowNode`, which is the line this
  package draws between a view and the assembling that feeds it: a view
  takes a node only where it reads more of one than its children.
  `TextNodeView` does, because a run becomes an `InlineSpan` and never a
  widget, so that recursion cannot leave the view at all. `TableNodeView`
  does, because it squares short rows off against the declared columns and
  resolves each cell's alignment against its own. `RawNodeView` is a leaf.
  The other two decide only how to place what they are given, so they take
  widgets and anyone can compose them — which is also what lets one
  `ColumnNodeView` serve a `ColumnNode`, a `TableCellNode` and the document
  root, none of which share a type.
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

- `NaturalBlockTheme` maps tones, emphasis, and custom marking to
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
  theme is opting out of that. `fromContext` takes `baseFontSize` from the
  ambient `textTheme.bodyMedium`, which is Material's own "ordinary text",
  so a document reads at the size the rest of the app does and nothing here
  restates a number Material already decided. The step a `:+` is worth
  cannot come from there: the Material scale runs 12, 14, 16, 22, 24, 28,
  32, 36, 45, 57, so its steps are not uniform, and a size does not even
  name a slot -- 14 is `bodyMedium`, `titleSmall` and `labelLarge` alike.
- `fromColorScheme` names only what a `ColorScheme` can answer. It used to
  take the other fields as arguments as well, which meant re-declaring six
  of the default constructor's defaults in a second place -- for no caller,
  anywhere, that ever passed one. `copyWith` covers them.
- "None" is written as a value, not as null: `const TableBorder()` has
  `BorderSide.none` on every side and measures the same as no border at all,
  and a `const BoxDecoration()` names no colour, border or shadow. That is
  what lets `copyWith` mean "leave this alone" for every omitted argument,
  the way Flutter's own `copyWith` methods do, with no sentinel standing in
  for "not passed". `tableStripe` stays nullable, because `Color` has no
  "none" of its own and a transparent one is still a fill -- it would put a
  decoration on every other row of every table.
- `styleFor(decoration, baseSize: ...)` is the whole mapping from what the
  source said to what is drawn: the tone, with emphasis and custom marking
  laid over it, at the size its `:+` and `:-` ask for. It lives on the theme
  because every value it needs is a field of one, and because a builder of
  your own would otherwise have to reproduce the order. It replaced a
  `styleFor(Tone)` that exposed only the first step, leaving the rest in the
  renderer -- and that was redundant with the tone fields anyway.
- `copyWith`, `==` / `hashCode`. The last two read one private list of the
  fields rather than naming each field twice, so they cannot come to disagree
  about what a theme is made of -- a field that reached `==` but not
  `hashCode` made two unequal themes hash alike, and the view compares themes
  to decide whether the tree it drew still holds. `NaturalBlockBuilders` is
  written the same way. The cost is a list per comparison where naming the
  fields allocated nothing, which is one or two per build of a document.

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
  theme, builders and handlers.
- A builder receives the node and one `NaturalBlockScope`, which carries the
  theme, the builders and the custom handlers. The three travel together the whole
  way down and no level swaps one of them for its children, so they are one
  value rather than three parameters repeated at every level.
- A builder gets no `BuildContext`, and neither do `buildLayouts` and
  `buildContents`. It was threaded through the whole layer and read by
  nothing in it -- every default builder only passed it on -- and existed so
  a builder of the caller's own could read an inherited widget. That
  possibility is what forced the view to drop its drawn tree from
  `didChangeDependencies`: a builder could have read anything, the tree
  cannot say what, so the only safe answer was to redraw the document on
  every ambient change. Returning a `Builder` reads one instead, which puts
  the dependency in an element of its own for Flutter to notify, so the
  document is kept and only that line redraws. The invalidation rule, the
  parameter and the test harness that existed to supply it all went with it.
- `RunHandler` lost its `BuildContext` for the same reason, where it was not
  a hazard but a defect. A handler that read a `MediaQuery` through the
  context it was handed drew the first value and then never moved again:
  a line keeps its spans until what they were built from changes, and what
  they were built from can never say what a handler went and read. There is
  no escape of the builders' kind either, because a `TextSpan` cannot read a
  context lazily, and dropping the spans on an ambient change would replace
  recognizers mid-gesture -- the one thing the line is built the way it is to
  avoid. Through `widgetRun(Builder(...))` the dependency sits in an element
  of its own and Flutter tracks it.
- The span building reads no context either, which fixed a second showing of
  the same fault: a raw run took its style from the ambient one directly
  while the line compared `rootStyle`. A theme whose `base` names a size
  makes `rootStyle` identical across an ambient size change, so the spans
  were kept and the raw run went on showing the old size. Every run of a
  line now starts from `rootStyle`, so `base` reaches a raw run as it
  reaches its neighbours, and the one value the line compares covers all.
  `RawNodeView` starts a raw block from `base` too, for the same reason.

### Raw regions

- A `` ` ``-fenced region renders monospaced, with whitespace and newlines
  exactly as written. Where it was written decides how it is drawn: a region
  that is a line's only content is a padded code block, one among other text
  is a monospaced run.
- `raw`, `rawPadding` and `rawDecoration` style it.
- `rawScrollsHorizontally` (off by default) makes long lines scroll
  rather than wrap. Wrapping is wrong for code, but turning this on puts a
  scroll view inside the caller's layout, which nothing else here does.

### Custom runs

- `customs` is the list of handlers a custom run is offered to, in
  order, until one claims it. The default list is empty: tappable text and
  each kind of image are things an app includes, so replacing a run and
  making it tappable are not the same switch.
- A handler is given the run as one `CustomRun` -- its text, the style it
  would have been drawn with, the theme, and the decoration the source gave
  it -- rather than as four arguments. Telling a handler one more thing is
  then a new field, which the handlers already written simply do not read,
  instead of a new parameter that every one of them must be edited to accept.
  `NaturalBlockImages.scaleOf` takes the run for the same reason.
- A handler answers with a `RunRendering`: the `InlineSpan` to put in the
  line, and the `dispose` that releases whatever that span carries. Returning
  a span rather than a description of one is what makes the extension point
  reach as far as Flutter does -- a `TextSpan` so a long run still wraps, a
  `TextSpan` with `children:` for text built from several styled pieces that
  must select as one, a `WidgetSpan` for a widget, a recognizer other than
  `TapGestureRecognizer` for a gesture other than a tap. It replaced a sealed
  pair (`TextRun` / `WidgetRun`) whose two cases bought the invariant "every
  span here is ours" by refusing everything in between.
- `dispose` is a required field rather than an omittable one, so a handler
  with nothing to release writes `() {}` and says so. That is the whole
  guard: nothing inspects a returned span, so a recognizer made without a
  `dispose` to match leaks in silence. Required-and-trivially-satisfied was
  chosen over a debug-only check that sweeps the span for a recognizer,
  because the check cannot see anything that is not a recognizer -- a stream
  subscription, a controller -- and the slot can. This is the contract
  `TextSpan.recognizer` already hands a caller; Flutter has no inline-link
  widget of its own (flutter#91600 is open), so the package is not standing
  in front of something better.
- `tappableText` is written through that public API, recognizer and
  `dispose` included, so it is also the worked example.
- `widgetRun(child)` is the other answer written down: a run drawn as a
  widget, centred on the text beside it, with the `dispose` that is correct
  for one. It is not a wrapper around `WidgetSpan`, because it disagrees with
  one: the alignment defaults to `middle` where `WidgetSpan`'s own default is
  `bottom`. Measured against 14-point text, a 20-point box centres at 10
  either way while the text centres at 10 for `middle` and 13 for `bottom`,
  so the default leaves the text hanging below what it sits beside. Of the
  alignments that cost the least line height -- `top`, `bottom` and `middle`
  all measure 20 against the baseline variants' 24 and 31 -- `middle` is the
  one that lines the two centres up. It was a private helper in
  `NaturalBlockImages` while the same three lines were being written by hand
  everywhere else -- the README's
  example, four test handlers, both image handlers -- each needing the same
  sentence about why an empty `dispose` is right. The `WidgetSpan` lifecycle
  is not an image's business, so it moved to where handlers are defined.
- What a tap means belongs to the handler that drew the run, so there is no
  `onTap` on the view. One for the whole view could only receive a string and
  guess which handler it came from. `tappableText` calls its `onTap` with the
  line's `BuildContext` when the run is tapped, through
  `CustomRun.withContext`, so a handler stays a top-level function -- its
  list `const` -- yet answers a tap with what is current then. The context
  reaches a handler only for later: calling `withContext` while drawing
  asserts, since what is read then would be baked into a line nothing
  redraws when it changes. It replaced an `onTap` taking only the text,
  which a handler needing the app's state had to capture as a method of
  that state, keeping its list out of `const`. Nothing here ever interprets
  the text: no URL is opened, and there is no `url_launcher` dependency.
- `NaturalBlockImages.network` is the reference rendering for the
  conventional `image(<url>)` payload, off until included: drawing a remote
  image is a network request to a third party made by displaying a
  document, which is a disclosure decision belonging to the app.
  `NaturalBlockImages.sourceOf` reads what a payload names and
  `NaturalBlockImages.kindOf` classifies it as network, file or relative,
  both without needing `dart:io`. `sourceOf`, not `urlOf`: a local payload
  names a path, and on Windows that is not a URL even by accident -- which
  is the whole trap `kindOf` exists for.
- `NaturalBlockImages.local` draws local files, and is a handler of its own
  rather than a setting on the first, because the two are different
  decisions: a remote image tells a third party the document was opened, a
  local one puts the reader's own file on screen under someone else's text.
  Separate handlers also make local-without-network expressible, which a
  superset entry point could not. `dart:io` stays off the web through a
  conditional import, so a local path there declines as it always did.
- A run is announced to a screen reader only when something is wired to it.
- `customs` is marked `@mustBeConst`, so the analyzer warns where it is not
  `const`. A list written afresh each build would redraw every line and lose
  a tap held across it, and a handler reading the app's state would draw it
  once and keep it; asking for `const` rules out both where they are
  written, instead of in a note to remember. A tap still reaches the app's
  state through the `BuildContext` `tappableText` hands its `onTap`.
