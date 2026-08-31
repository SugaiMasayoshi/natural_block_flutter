## 0.0.1

* Initial release.
* `NaturalBlockView`: parses a `natural_block` markup `source` string and renders it as Flutter widgets.
* `NaturalBlockTheme`: maps semantic colors (danger/success/info/none) and emphasis to `TextStyle`s.
* `NaturalBlockRegistry`: maps AST node types (`RowNode`, `ColumnNode`, `TextNode`) to the widget builders that render them, with `register`/`registerAll` for overriding or extending the defaults per node type.
* Default `NodeBuilder`s for `RowNode`, `ColumnNode`, and `TextNode`, exported for reuse by custom builders.
