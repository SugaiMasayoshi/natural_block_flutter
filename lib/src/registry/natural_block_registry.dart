import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../widget/natural_block_theme.dart';
import 'default_builders.dart';

/// Builds widget(s) for the node at [siblings]\[index\], optionally consuming
/// more than one sibling starting at that index.
typedef NodeBuilder =
    NodeBuildResult Function(
      BuildContext context,
      List<NaturalBlockNode> siblings,
      int index,
      NaturalBlockTheme theme,
      NaturalBlockRegistry registry,
    );

/// The result of a [NodeBuilder] call.
class NodeBuildResult {
  /// The widget rendered for the consumed sibling(s).
  final Widget widget;

  /// How many entries of `siblings`, starting at `index`, this result covers.
  final int consumedCount;

  const NodeBuildResult({required this.widget, this.consumedCount = 1})
    : assert(consumedCount >= 1);
}

/// Maps [NaturalBlockNode] types to the [NodeBuilder] that renders them.
///
/// Lookup in [buildAll] is keyed by `runtimeType`, not by `is`/type
/// hierarchy: a subclass of a registered node type (e.g. a consumer's own
/// subclass of `TextNode`) does **not** match the builder registered for
/// its supertype. It falls through to the fallback builder, which renders
/// nothing and (in debug mode only) prints a warning via `debugPrint`. If
/// you introduce a node subclass, register a builder for that exact type.
class NaturalBlockRegistry {
  final Map<Type, NodeBuilder> _builders;

  const NaturalBlockRegistry._(this._builders);

  /// The [NodeBuilder]s registered on [defaults]. Private: it exists only
  /// so [defaults] can be built as a `const`, not as something consumers
  /// should read or reuse directly -- use [defaults] and [register] /
  /// [registerAll] instead.
  static const Map<Type, NodeBuilder> _defaultBuilders = {
    RowNode: buildRowNode,
    ColumnNode: buildColumnNode,
    TextNode: buildTextNode,
  };

  /// The registry used by `NaturalBlockView` unless a custom `registry` is
  /// supplied: builders for [RowNode], [ColumnNode], and [TextNode] backed
  /// by `RowNodeView`, `ColumnNodeView`, and `TextNodeView` respectively.
  static const NaturalBlockRegistry defaults = NaturalBlockRegistry._(
    _defaultBuilders,
  );

  /// Creates a registry with no builders registered. Every node hits the
  /// fallback builder (renders nothing; debug-mode-only warning) unless you
  /// [register] builders for the node types you need -- prefer starting
  /// from [defaults] and overriding via [register] unless you specifically
  /// want to opt out of the built-in Row/Column/Text rendering.
  const NaturalBlockRegistry.empty() : _builders = const {};

  /// Returns a new registry with [builder] registered for [type], overriding
  /// any existing builder for that type.
  NaturalBlockRegistry register(Type type, NodeBuilder builder) =>
      NaturalBlockRegistry._({..._builders, type: builder});

  /// Returns a new registry with all of [builders] registered, overriding
  /// any existing builders for those types.
  NaturalBlockRegistry registerAll(Map<Type, NodeBuilder> builders) =>
      NaturalBlockRegistry._({..._builders, ...builders});

  /// Builds widgets for every node in [nodes], letting each builder decide
  /// how many consecutive nodes it consumes.
  ///
  /// The builder for each node is looked up by `nodes[index].runtimeType`
  /// -- an exact type match, not `is`/subtype matching. A node whose
  /// runtime type isn't a key of this registry (including a subclass of a
  /// registered type) hits the fallback builder, which renders nothing and
  /// -- in debug mode only -- prints a warning via `debugPrint`.
  List<Widget> buildAll(
    BuildContext context,
    List<NaturalBlockNode> nodes,
    NaturalBlockTheme theme,
  ) {
    final widgets = <Widget>[];
    var index = 0;
    while (index < nodes.length) {
      final builder = _builders[nodes[index].runtimeType] ?? _buildFallback;
      final result = builder(context, nodes, index, theme, this);
      widgets.add(result.widget);
      index += result.consumedCount;
    }
    return widgets;
  }

  static NodeBuildResult _buildFallback(
    BuildContext context,
    List<NaturalBlockNode> siblings,
    int index,
    NaturalBlockTheme theme,
    NaturalBlockRegistry registry,
  ) {
    if (kDebugMode) {
      debugPrint(
        'NaturalBlockRegistry: no builder registered for '
        '${siblings[index].runtimeType}; rendering nothing.',
      );
    }
    return const NodeBuildResult(widget: SizedBox.shrink());
  }
}
