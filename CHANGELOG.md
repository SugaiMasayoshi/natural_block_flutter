## Unreleased

- `CustomRun.argumentOf(name)` reads a `name(<argument>)` payload, the shape
  `image(<source>)` has, without a regular expression.

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
