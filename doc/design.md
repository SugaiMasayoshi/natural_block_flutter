# Design notes

Why the renderer is the way it is, and what it used to be. The README says
how to use it; this says why.

## The view and its caches

- `natural_block` is re-exported. Builders and handlers are written against
  its types -- `NodeBuilder<RowNode>`, `CustomRun.decoration` -- so one
  import covers them, with no second dependency to add.
- `NaturalBlockView` parses once per source, not once per build: the tree
  owes nothing to the `BuildContext`, so an ancestor rebuilding -- a theme
  change, an animating parent, a scroll -- reuses it, and only a new
  `source` re-parses.
- It keeps the drawn tree too, and hands back the very same widget object
  when nothing it was drawn from has changed. That is the one thing Flutter
  watches for: `updateChild` stops at a child whose widget has not changed,
  so the whole document is skipped rather than rebuilt. `const` is the
  framework's own version of this and cannot apply here, since a parsed
  document is not a compile-time value. Measured on a debug build, an
  ancestor rebuild of a 50-paragraph document went from 12.2ms to 7.0ms.
- What it compares is the `NaturalBlockScope` it drew with, and the document
  -- not a second list of the same fields kept for comparing. That second
  list is a place for a field to reach the drawing and not the comparison,
  and then a change never redraws; `NaturalBlockScope` carries value
  equality so there is one list instead of two.
- `customs` and `builders` are marked `@mustBeConst`. A list written afresh
  each build would redraw every line and lose a tap held across it, and a
  handler reading the app's state would draw it once and keep it; asking
  for `const` rules out both where they are written, instead of in a note
  to remember. A `NaturalBlockScope` is made by the view and never by hand
  -- its constructor is `@internal` -- because a scope made elsewhere could
  carry a list that is new on every build.

## Lines

- `TextNodeView` builds with `Text.rich` so the result takes part in text
  selection. A directly constructed `RichText` never registers with the
  selection machinery, so a `SelectionArea` around one would do nothing.
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
- Turning a line into spans hands back the spans and, separately, whatever
  needs releasing. Nothing ever asks which `dispose` belongs to which span,
  so pairing them cost a record per run that was built, destructured, and
  then held for the life of the line. Only a run a handler claims adds
  anything now, so a line of ordinary text has nothing to release at all.
  Measured in one session against the shape it replaced: 156ns per run
  became 143ns for a line of a thousand runs, and 180ns became 129ns for a
  line of twenty.
- Every run of a line starts from one expression: the ambient style with the
  theme's `base` merged over it. The root span and the baseline a `:+`
  counts from were once computed separately, and a theme whose `base` named
  a size made `:+` render smaller than the text beside it. A raw run once
  took its style from the ambient one directly while the line compared the
  root style, so under a `base` that names a size the spans were kept across
  an ambient size change and the raw run went on showing the old size.
  `RawNodeView` starts a raw block from `base` too, for the same reason.
- Every list whose length is known before it is filled is built with
  `List.generate` rather than a collection-for. A collection-for and a
  hand-written `add` measure the same, because both grow a list and pay for
  the reallocation; pre-sizing is what costs less. Compiled ahead of time and
  measured on list building alone, a thousand elements cost 22.5us one way
  and 3.9us the other. A loop stays a loop where no list comes out of it.

## Layout

- Unstated and `HorizontalAlign.start` both draw at the start; what keeps
  them apart is a table, where a cell that stated nothing is drawn with its
  column instead. A non-start block is wrapped in `Align` rather than a
  width-filling box, so adding an alignment marker can never make a document
  stop rendering where the available width is unbounded. The raw block's box
  is never stretched for the same reason.
- The mapping from `HorizontalAlign` to Flutter layout lives in one `switch`
  in `ColumnNodeView`, which blocks and table cells both draw through. Both
  views used to hold a copy of it, one written as a `switch` statement and
  one as a switch expression, which made the duplication easy to miss.
- `RowNodeView` gives each cell an equal share of the width, which is what
  keeps columns lined up between rows, and what makes `左^^右` push `右` to
  the far edge. Where the width is unbounded there is no width to divide, so
  it falls back to shrink-wrapped cells -- a degradation, since columns then
  stop lining up and alignment markers become no-ops, but better than not
  rendering.
- A view takes a node only where it reads more of one than its children.
  `TextNodeView` does, because a run becomes an `InlineSpan` and never a
  widget, so that recursion cannot leave the view at all. `TableNodeView`
  does, because it squares short rows off and resolves each cell's
  alignment. `RawNodeView` is a leaf. `RowNodeView` and `ColumnNodeView`
  decide only how to place what they are given, so they take widgets and
  anyone can compose them -- which is also what lets one `ColumnNodeView`
  serve a `ColumnNode`, a `TableCellNode` and the document root, none of
  which share a type.
- `TableNodeView` does the two things the tree deliberately leaves undone:
  it squares short rows off to the table's width (Flutter's `TableRow`
  requires every row to hold the same number of children) and resolves each
  cell's alignment against its column. Both are questions about drawing,
  asked of a tree that records only what the author wrote.
- A table's border defaults to hairlines on every edge, outer frame
  included: a table is the one construct with a declared beginning and end,
  so a frame states something the source actually says.

## Theming

- A view given no theme uses `fromContext`, so a document reads correctly in
  a light theme and a dark one without being told which it is in. Passing a
  theme is opting out of that. `fromContext` takes `baseFontSize` from the
  ambient `textTheme.bodyMedium`, which is Material's own "ordinary text",
  so a document reads at the size the rest of the app does and nothing here
  restates a number Material already decided. The step a `:+` is worth
  cannot come from there: the Material scale runs 12, 14, 16, 22, 24, 28,
  32, 36, 45, 57, so its steps are not uniform, and a size does not even
  name a slot -- 14 is `bodyMedium`, `titleSmall` and `labelLarge` alike.
- Striping lives on `fromColorScheme` rather than on the default constructor
  because a band must be darker than the surface in a light theme and
  lighter in a dark one, so no single constant can serve both. The raw
  block's box is derived there for the same reason: a fixed translucent
  black moves a light surface by about ten steps per channel and a dark one
  by one, which is invisible.
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
- `styleFor` is the whole mapping from what the source said to what is
  drawn. It lives on the theme because every value it needs is a field of
  one, and because a builder of your own would otherwise have to reproduce
  the order. It replaced a `styleFor(Tone)` that exposed only the first
  step, leaving the rest in the renderer.
- `==` and `hashCode` read one private list of the fields rather than naming
  each field twice, so they cannot come to disagree about what a theme is
  made of -- a field that reached `==` but not `hashCode` made two unequal
  themes hash alike, and the view compares themes to decide whether the tree
  it drew still holds. `NaturalBlockBuilders` is written the same way. The
  cost is a list per comparison, which is one or two per build of a
  document.
- Code is monospaced because in a region whose whole point is exactness,
  indentation and the difference between `l` and `1` are part of the
  content. `rawScrollsHorizontally` is off by default: wrapping is wrong for
  code, but turning it on puts a scroll view inside the caller's layout,
  which nothing else here does.

## Builders

- `NaturalBlockBuilders` holds one builder per kind of node. The node types
  are sealed, so the set is closed and can be named: the builder's node type
  stays exact, nothing is cast on the way in, and a builder written for the
  wrong kind does not compile. It replaced a `Type`-keyed map, which
  modelled an openness the AST does not have and needed a fallback for types
  that cannot occur.
- The default builders are exported so a builder of your own can delegate
  back. Naming one that way also keeps `NaturalBlockBuilders` const.
- Choosing between the fields is `buildLayouts` / `buildContents`' job, and
  they are the only places the tree says merely that one of several kinds is
  there. Each switches over a sealed set small enough to be exhaustive, so
  the nodes that are never drawn on their own -- the document, a table's
  rows, the runs -- cannot be handed to a builder at all. Where the tree
  already names one kind, as a table's cells do, there is nothing to choose
  and the field is called directly.
- The theme, the builders and the handlers travel together the whole way
  down and no level swaps one of them for its children, so they are one
  value, `NaturalBlockScope`, rather than three parameters repeated at every
  level.
- A builder gets no `BuildContext`. It was threaded through the whole layer
  and read by nothing in it -- every default builder only passed it on --
  and existed so a builder of the caller's own could read an inherited
  widget. That possibility is what forced the view to drop its drawn tree
  from `didChangeDependencies`: a builder could have read anything, the tree
  cannot say what, so the only safe answer was to redraw the document on
  every ambient change. Returning a `Builder` reads one instead, which puts
  the dependency in an element of its own for Flutter to notify, so the
  document is kept and only that line redraws.
- `RunHandler` lost its `BuildContext` for the same reason, where it was not
  a hazard but a defect. A handler that read a `MediaQuery` through the
  context it was handed drew the first value and then never moved again: a
  line keeps its spans until what they were built from changes, and what
  they were built from can never say what a handler went and read. There is
  no escape of the builders' kind either, because a `TextSpan` cannot read a
  context lazily, and dropping the spans on an ambient change would replace
  recognizers mid-gesture. Through `widgetRun(Builder(...))` the dependency
  sits in an element of its own and Flutter tracks it.

## Custom runs

- This package does not call a custom run a link. The parser only records
  that a run is custom; what tapping it means is the app's decision. Nothing
  here ever interprets the text: no URL is opened, and there is no
  `url_launcher` dependency.
- The default `customs` is empty: tappable text and each kind of image are
  things an app includes, so replacing a run and making it tappable are not
  the same switch. With no handler a custom run is still styled, but it is
  announced to a screen reader as interactive only when something is wired
  to it -- claiming otherwise would be a promise nothing keeps.
- A handler is given the run as one `CustomRun` rather than as several
  arguments. Telling a handler one more thing is then a new field, which the
  handlers already written simply do not read, instead of a new parameter
  that every one of them must be edited to accept. It is a class rather than
  a record: a record's shape is its type, so one more field would break
  every record literal and pattern of it. `NaturalBlockImages.scaleOf` takes
  the run for the same reason.
- A handler answers with a `RunRendering`: the `InlineSpan` to put in the
  line, and the `dispose` that releases whatever that span carries.
  Returning a span rather than a description of one is what makes the
  extension point reach as far as Flutter does -- a `TextSpan` so a long run
  still wraps, a `TextSpan` with `children:` for text built from several
  styled pieces that must select as one, a `WidgetSpan` for a widget, a
  recognizer other than `TapGestureRecognizer` for a gesture other than a
  tap. It replaced a sealed pair (`TextRun` / `WidgetRun`) whose two cases
  bought the invariant "every span here is ours" by refusing everything in
  between.
- `dispose` is required rather than omittable, so a handler with nothing to
  release writes `() {}` and says so. That is the whole guard: nothing
  inspects a returned span, so a recognizer made without a `dispose` to
  match leaks in silence. Required-and-trivially-satisfied was chosen over a
  debug-only check that sweeps the span for a recognizer, because the check
  cannot see anything that is not a recognizer -- a stream subscription, a
  controller -- and the slot can. This is the contract `TextSpan.recognizer`
  already hands a caller; Flutter has no inline-link widget of its own
  ([flutter#91600](https://github.com/flutter/flutter/issues/91600) is
  open), so the package is not standing in front of something better.
- `tappableText` is written through that public API, recognizer and
  `dispose` included, so it is also the worked example.
- `widgetRun(child)` is not a wrapper around `WidgetSpan`, because it
  disagrees with one: the alignment defaults to `middle` where
  `WidgetSpan`'s own default is `bottom`. Measured against 14-point text, a
  20-point box centres at 10 either way while the text centres at 10 for
  `middle` and 13 for `bottom`, so the default leaves the text hanging below
  what it sits beside. Of the alignments that cost the least line height --
  `top`, `bottom` and `middle` all measure 20 against the baseline variants'
  24 and 31 -- `middle` is the one that lines the two centres up. It was a
  private helper in `NaturalBlockImages` while the same three lines were
  being written by hand everywhere else, each needing the same sentence
  about why an empty `dispose` is right.
- What a tap means belongs to the handler that drew the run, so there is no
  `onTap` on the view. One for the whole view could only receive a string
  and guess which handler it came from. `tappableText` calls its `onTap`
  with the line's `BuildContext` through `CustomRun.withContext`, so a
  handler stays a top-level function -- its list `const` -- yet answers a
  tap with what is current then. Calling `withContext` while drawing
  asserts, since what is read then would be baked into a line nothing
  redraws when it changes. It replaced an `onTap` taking only the text,
  which a handler needing the app's state had to capture as a method of
  that state, keeping its list out of `const`.

## Images

- There is no image syntax. An image is a custom run with the payload
  `image(<url>)`, so an implementation that has never heard of images still
  shows readable text. The word is spelled out, and `img` is not accepted as
  an alias: what the reader sees when nothing renders the payload is the
  whole point of the convention, and two spellings would be exactly the
  dialect it exists to prevent. Whitespace is never trimmed for the same
  reason: `image( a.png )` reads as text, so a mistake shows up where it was
  made.
- Shipping a reference implementation is the point: declining to interpret
  would not prevent dialects, it would guarantee them, with every app
  inventing its own spelling.
- `NaturalBlockImages.network` is off until included. Drawing a remote image
  is a request to a third party made by displaying a document, and a URL
  carrying a per-recipient marker turns that into a read receipt. The
  package cannot tell those apart, so the disclosure decision belongs to the
  app -- the same reason mail clients block remote images by default.
- `NaturalBlockImages.local` is a handler of its own rather than a setting
  on the first, because the two are different decisions: a remote image
  tells a third party the document was opened, a local one puts the
  reader's own file on screen under someone else's text, and lets a
  document probe which paths exist from whether they draw. Separate handlers
  also make local-without-network expressible. `dart:io` stays off the web
  through a conditional import, so a local path there declines.
- `sourceOf`, not `urlOf`: a local payload names a path, and on Windows that
  is not a URL even by accident. `kindOf` exists because `Uri.parse` reads
  `C:\Users\a.png` as a URI whose scheme is `c`, so "has a scheme, so it is
  a URL" mistakes every Windows path for one.
