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

  @internal
  const NaturalBlockScope({
    this.theme = const NaturalBlockTheme(),
    this.builders = NaturalBlockBuilders.defaults,
    this.customs = const [],
  });

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

  final NodeBuilder<CellNode> cell;

  final NodeBuilder<ColumnNode> column;

  final NodeBuilder<TableNode> table;

  final NodeBuilder<TableCellNode> tableCell;

  final NodeBuilder<TextNode> text;

  final NodeBuilder<RawNode> raw;

  /// The default takes the spacer's share of the height left over; another
  /// widget, such as a gap of a fixed height, takes its own.
  final NodeBuilder<SpacerNode> spacer;

  const NaturalBlockBuilders({
    this.row = buildRowNode,
    this.cell = buildCellNode,
    this.column = buildColumnNode,
    this.table = buildTableNode,
    this.tableCell = buildTableCellNode,
    this.text = buildTextNode,
    this.raw = buildRawNode,
    this.spacer = buildSpacerNode,
  });

  static const NaturalBlockBuilders defaults = NaturalBlockBuilders();

  List<Object?> get _fields => [
    row,
    cell,
    column,
    table,
    tableCell,
    text,
    raw,
    spacer,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NaturalBlockBuilders && listEquals(_fields, other._fields);

  @override
  int get hashCode => Object.hashAll(_fields);
}
