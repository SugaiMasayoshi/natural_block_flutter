# natural_block_flutter example

A demo app for the [`natural_block_flutter`](../README.md) package.

It has two parts:

* **Playground** -- a text field at the top where you can type `natural_block` markup and see it rendered live, using `NaturalBlockView`.
* **Sample gallery** -- a scrollable list of markup snippets, each shown alongside its rendered output: plain text, semantic colors, combined color+emphasis, size steps, punctuation that needs no escaping, escaping when it is needed, row and column layout, block alignment, actionable text, tables (including per-column alignment and closing one), and images.

The app wires up the optional pieces so they can be seen working: `onActionTap` reports taps, `onActionBuild` is given `NaturalBlockImages.builder` so `image(...)` payloads draw, everything is wrapped in a `SelectionArea` so the text is selectable, and a theme derived from the app's own `ColorScheme` can be toggled between plain and striped tables, and between light and dark.

## Running it

```bash
cd example
flutter run
```

You can also preview just the demo page, without launching the full app, via:

```bash
flutter widget-preview start
```
