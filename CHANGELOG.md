## 0.4.0

- Breaking: built on the `material_ui` package, where Flutter 3.50
  deprecates `package:flutter/material.dart`. `resolve` takes its
  `ColorScheme`, and `NaturalBlockView` finds its `Theme`, so an app moves
  to `material_ui` too, with `dart fix --apply --code=migrate_design_widgets`.
  Requires Flutter 3.47.
- Requires natural_block 0.4.0, whose code inside a line carries the
  decoration around it.
- With a `height` in `NaturalBlockTheme.base`, the space kept the same in
  pixels at every size is what the height adds to the font's own line
  height, where it was what it added to the font size. A large line no
  longer stands closer than its glyphs, so they stay off the next line.
- Code inside a line is drawn with the decoration around it, as natural_block
  now gives it: at the line's size, in its tone and weight, in `raw`'s font.
- The default `raw` falls back to Menlo, Consolas and Courier New where
  `monospace` is missing, so code is monospaced on Windows, macOS and iOS
  too, where it was drawn in the body font.

## 0.3.0

- Draws natural_block's spacer, a line of `|` alone: where the height has an
  upper bound, spacers share out what the content leaves, by their `flex`,
  and elsewhere take none. A row's cell may take up to the row's height,
  and one that grows into it, as a cell with a spacer does, runs from the
  top of the row; so `^Image^|\nCaption\n|^` centers the caption beside the
  image. The other cells still line up on their first baseline. Breaking:
  `RowNodeView` lays out its cells itself rather than through a `Row`. The new
  `spacer` builder draws a spacer: by default a `SpacerNodeView`, which
  takes the share when a `SpacerRoom` says there is one and draws its
  `child` there, and in its place any widget, such as a fixed gap.
- Breaking: a `NaturalBlockTheme` takes the colors it leaves open from a
  `ColorScheme` through `resolve`, which `NaturalBlockView` does with the
  ambient one, so a theme written with the constructor follows dark mode.
  The tone and custom styles are laid over the scheme's colors;
  `tableBorder` and `rawDecoration` are null until resolved, and `striped`
  bands tables. `fromColorScheme` and `fromContext` are gone: write
  `NaturalBlockTheme(striped: true)`, or `theme.resolve(scheme)` for a
  scheme other than the app's.
- Requires natural_block 0.3.0, whose row cells are `CellNode`s. The new
  `cell` builder draws one, by default stacking its blocks and spacers as a
  document's are.
- A blank line that ends a block, before the next one, is a body line high,
  where it took the height of the line above it, as large as a heading.
- Code inside a line takes `rawDecoration`'s color as its background, as a
  code block does, so it stands apart from the text around it.
- `NaturalBlockImages.networkImage` and `localImage` give the image the
  `network` and `local` handlers draw, as a widget, so an app can wrap it,
  to bound its size for one, and draw it with `widgetRun`.
- Breaking: a `:+` / `:-` step scales an image from the size its space
  leaves it, where it scaled the image's own size before the space bounded
  it. A `:-` now shrinks an image wider than its space, and a `:+` stops at
  the space. `NaturalBlockImages.scaleOf` is gone.
- `NaturalBlockImages.localImage` takes a `path` the app resolved, from the
  document's folder for one, and still shows the payload as written when
  the file cannot be drawn.
- natural_block's `payloadArgument(payload, name)`, which reads a
  `name(<argument>)` payload, the shape `image(<source>)` has, is
  re-exported, so a handler reads `payloadArgument(run.text, 'note')`.
- `NaturalBlockView.document` draws a `DocumentNode` already parsed.
- With a `height` in `NaturalBlockTheme.base`, `:+` and `:-` keep the space
  it adds around a line the same in pixels, where it grew with the size. A
  large line no longer carries a wide gap, so blank lines read the same next
  to any size.
- A row's cells line up on the baseline of their first lines, where they
  lined up at the top. `^:++A^B^` now sets `B` on the line `A` stands on;
  cells whose first lines are the same size and font stay where they were.
- Breaking: `NaturalBlockTheme.fontScaleFor` sizes `:+` and `:-` as a ratio
  of the text around the view, 1.2 per step by default. It replaces
  `baseFontSize`, `fontSizeStep` and `minFontSize`; set the body size with
  `base: TextStyle(fontSize: ...)`, or leave it to the ambient text.
- Breaking: `NaturalBlockView` is sealed, and a view no longer exposes the
  `source` it was given. A test finds views with
  `find.bySubtype<NaturalBlockView>()`, since `find.byType` matches none.

## 0.2.0

- Requires natural_block 0.2.0, where `~` opens and closes a table only at
  the start of a line or of a row's cell.
- `fromColorScheme` and `fromContext` draw the positive tone green, toned
  for the brightness, instead of the scheme's `tertiary`, which can be as red
  as `error`.

## 0.1.0

- Initial release.
- `NaturalBlockView` renders a `natural_block` source as `Column`, `Row`,
  `Table` and selectable `Text.rich` widgets.
- `NaturalBlockTheme` maps tones, emphasis, size steps, tables and raw
  regions to styles, with `fromContext` for light and dark themes.
- `NaturalBlockBuilders` replaces the widget for any kind of node.
- `customs` handlers draw custom runs: `tappableText`, `widgetRun`, and
  `NaturalBlockImages.network` / `.local` for the `image(<url>)` convention.
