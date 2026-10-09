import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../widget/natural_block_theme.dart';
import 'default_builders.dart';
import 'run_handler.dart';

/// Draws one node of kind [T].
///
/// No `BuildContext`: a builder is called while its parent builds, so reading
/// an inherited widget here would bake what it read into a tree that cannot
/// say what that was -- and the view would have to redraw the whole document
/// on every ambient change, because it could never know whether this one
/// cared. Return a `Builder` to read one, and the dependency is Flutter's to
/// track, where it belongs.
typedef NodeBuilder<T extends NaturalBlockNode> = Widget Function(
  T node,
  NaturalBlockScope scope,
);

/// Everything a node needs to draw itself that is not the node.
///
/// The three travel together the whole way down -- a table hands them to its
/// rows, a row to its cells, a cell to its lines -- and no level chooses a
/// different one of them for its children. Carried as one value they are
/// declared once instead of at every level, and adding a fourth thing later
/// does not rewrite every signature in between.
///
/// There is no `BuildContext` here, or in [NodeBuilder]: see there for why.
class NaturalBlockScope {
  final NaturalBlockTheme theme;

  final NaturalBlockBuilders builders;

  /// The handlers an actionable run is offered to, in order, and what
  /// the app wants done when one is tapped.
  final List<RunHandler> customs;

  final OnActionTap? onTap;

  const NaturalBlockScope({
    this.theme = const NaturalBlockTheme(),
    this.builders = NaturalBlockBuilders.defaults,
    this.customs = const [tappableText],
    this.onTap,
  });
}

/// Which widget draws each kind of node.
///
/// A field per kind rather than a `Type`-keyed map: the node types are
/// sealed, so the set is closed and known here. Naming each one keeps the
/// builder's node type exact -- the node arrives as `RowNode`, not as
/// something to narrow, and a builder written for the wrong kind does not
/// compile. Choosing between the fields is `natural_block_render.dart`'s
/// job; this is the table it chooses from.
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
