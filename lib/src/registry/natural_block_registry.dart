import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../widget/natural_block_theme.dart';
import 'default_builders.dart';

typedef NodeBuilder = Widget Function(
  BuildContext context,
  NaturalBlockNode node,
  NaturalBlockScope scope,
);

typedef OnActionTap = void Function(String text);

typedef ActionSpanBuilder = InlineSpan? Function(
  BuildContext context,
  String text,
  TextStyle style,
  NaturalBlockTheme theme,
);

class NaturalBlockActions {
  final OnActionTap? onTap;

  final ActionSpanBuilder? buildSpan;

  const NaturalBlockActions({this.onTap, this.buildSpan});

  static const NaturalBlockActions none = NaturalBlockActions();
}

/// Everything a node needs to draw itself that is not the node.
///
/// The three travel together the whole way down -- a table hands them to its
/// rows, a row to its cells, a cell to its lines -- and no level chooses a
/// different one of them for its children. Carried as one value they are
/// declared once instead of at every level, and adding a fourth thing later
/// does not rewrite every signature in between.
///
/// The `BuildContext` is deliberately *not* in here. It is the one thing that
/// does differ per level, and keeping it out is what lets the default builder
/// map stay `const`.
class NaturalBlockScope {
  final NaturalBlockTheme theme;

  final NaturalBlockRegistry registry;

  final NaturalBlockActions actions;

  const NaturalBlockScope({
    this.theme = const NaturalBlockTheme(),
    this.registry = NaturalBlockRegistry.defaults,
    this.actions = NaturalBlockActions.none,
  });

  /// Builds a widget for each of [nodes], whatever kind they are.
  ///
  /// Typed as broadly as the lookup is: builders are found by exact
  /// `runtimeType`, so a document's blocks and a block's lines go through the
  /// same call. Narrowing this to one of them would only bar the other from
  /// a mechanism that already serves it.
  List<Widget> buildAll(BuildContext context, List<NaturalBlockNode> nodes) => [
    for (final node in nodes) registry.builderFor(node)(context, node, this),
  ];
}

class NaturalBlockRegistry {
  final Map<Type, NodeBuilder> _builders;

  const NaturalBlockRegistry._(this._builders);

  static const Map<Type, NodeBuilder> _defaultBuilders = {
    RowNode: buildRowNode,
    TableNode: buildTableNode,
    ColumnNode: buildColumnNode,
    TableCellNode: buildTableCellNode,
    TextNode: buildTextNode,
    RawNode: buildRawNode,
  };

  static const NaturalBlockRegistry defaults = NaturalBlockRegistry._(
    _defaultBuilders,
  );

  const NaturalBlockRegistry.empty() : _builders = const {};

  NaturalBlockRegistry register(Type type, NodeBuilder builder) =>
      NaturalBlockRegistry._({..._builders, type: builder});

  NaturalBlockRegistry registerAll(Map<Type, NodeBuilder> builders) =>
      NaturalBlockRegistry._({..._builders, ...builders});

  /// The builder registered for [node]'s exact type, or the one that draws
  /// nothing and says so.
  NodeBuilder builderFor(NaturalBlockNode node) =>
      _builders[node.runtimeType] ?? _buildFallback;

  static Widget _buildFallback(
    BuildContext context,
    NaturalBlockNode node,
    NaturalBlockScope scope,
  ) {
    if (kDebugMode) {
      debugPrint(
        'NaturalBlockRegistry: no builder registered for '
        '${node.runtimeType}; rendering nothing.',
      );
    }
    return const SizedBox.shrink();
  }
}
