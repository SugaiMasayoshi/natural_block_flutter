import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../widget/natural_block_theme.dart';
import 'default_builders.dart';
import 'run_handler.dart';

/// Draws one node of kind [T].
///
/// No `BuildContext`: reading an inherited widget here would bake what it
/// read into a tree that cannot say what that was, so the view would have
/// to redraw the whole document on every ambient change. Return a
/// `Builder` instead and the dependency is Flutter's to track.
typedef NodeBuilder<T extends NaturalBlockNode> = Widget Function(
  T node,
  NaturalBlockScope scope,
);

/// Everything a node needs to draw itself that is not the node.
///
/// They travel together the whole way down and no level swaps one of them
/// for its children, so they are one value rather than parameters repeated
/// at every level. No `BuildContext` here either: see [NodeBuilder].
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

  /// What a document is drawn from, which is therefore also what decides
  /// whether the one already drawn still holds.
  ///
  /// One list for both: a second one, kept for comparing, is a place for a
  /// field to reach the drawing and not the comparison -- and then a change
  /// never redraws. `customs` compares as a list does, by identity, which is
  /// why a view's `customs` asks for a stable one.
  List<Object?> get _fields => [theme, builders, customs, onTap];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NaturalBlockScope && listEquals(_fields, other._fields);

  @override
  int get hashCode => Object.hashAll(_fields);
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
