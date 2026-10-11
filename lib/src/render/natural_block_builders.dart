import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../custom/run_handler.dart';
import '../widget/natural_block_theme.dart';
import 'default_builders.dart';

/// Draws one node of kind [T].
///
/// No `BuildContext`: return a `Builder` to read an inherited widget, so
/// Flutter tracks the dependency.
typedef NodeBuilder<T extends NaturalBlockNode> = Widget Function(
  T node,
  NaturalBlockScope scope,
);

/// Everything a node needs to draw itself that is not the node.
class NaturalBlockScope {
  final NaturalBlockTheme theme;

  final NaturalBlockBuilders builders;

  /// The handlers a custom run is offered to, in order.
  final List<RunHandler> customs;

  const NaturalBlockScope({
    this.theme = const NaturalBlockTheme(),
    this.builders = NaturalBlockBuilders.defaults,
    this.customs = const [],
  });

  /// What a document is drawn from, which is therefore also what decides
  /// whether the one already drawn still holds.
  ///
  /// One list for both: a second one, kept for comparing, is a place for a
  /// field to reach the drawing and not the comparison -- and then a change
  /// never redraws. `customs` compares as a list does, by identity, which is
  /// why a view's `customs` asks for a stable one.
  List<Object?> get _fields => [theme, builders, customs];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NaturalBlockScope && listEquals(_fields, other._fields);

  @override
  int get hashCode => Object.hashAll(_fields);
}

/// Which widget draws each kind of node.
class NaturalBlockBuilders {
  final NodeBuilder<RowNode> row;

  final NodeBuilder<ColumnNode> column;

  final NodeBuilder<TableNode> table;

  final NodeBuilder<TableCellNode> tableCell;

  final NodeBuilder<TextNode> text;

  final NodeBuilder<RawNode> raw;

  const NaturalBlockBuilders({
    this.row = buildRowNode,
    this.column = buildColumnNode,
    this.table = buildTableNode,
    this.tableCell = buildTableCellNode,
    this.text = buildTextNode,
    this.raw = buildRawNode,
  });

  static const NaturalBlockBuilders defaults = NaturalBlockBuilders();

  /// Two registries are equal when they name the same builder for every kind.
  ///
  /// Worth having because the view compares registries to decide whether the
  /// tree it drew is still good. A function written out as a literal is never
  /// equal to another, so builders built inline in a `build` compare as
  /// changed every time -- which costs a rebuild, never correctness. Naming
  /// the builders (a top-level function, or a method on your state) makes
  /// this hold.
  List<Object?> get _fields => [row, column, table, tableCell, text, raw];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NaturalBlockBuilders && listEquals(_fields, other._fields);

  @override
  int get hashCode => Object.hashAll(_fields);
}
