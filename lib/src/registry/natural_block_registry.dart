// 【解説】[15/16] ノードの型 → 描画関数 の対応表。差し替え機構。
// 【解説】
// 【解説】 利用者が register() で任意のノード型の描画を差し替えられる。これがあるので
// 【解説】 「見出しだけ自前のウィジェットで描く」といったことがフォークせずにできる。
// 【解説】
// 【解説】 注意点が1つ、docにも明記してある: 引きは runtimeType の完全一致で、
// 【解説】 is/継承では引かない。TextNode を継承した独自クラスは TextNode の
// 【解説】 ビルダーに当たらず、フォールバック(何も描かず、デバッグ時のみ警告)に落ちる。
// 【解説】 次: lib/src/registry/default_builders.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../widget/natural_block_theme.dart';
import 'default_builders.dart';

/// Builds the widget for a single [BlockNode].
typedef NodeBuilder =
    Widget Function(
      BuildContext context,
      BlockNode node,
      NaturalBlockTheme theme,
      NaturalBlockRegistry registry,
      OnActionTap? onActionTap,
    );

/// Called when an actionable span (`TextSpanNode.isAction == true`, written
/// as `:@...:@` in `natural_block` markup) is tapped, with that span's own
/// `text`. The parser and this package never interpret [text] -- deciding
/// what it means (a URL to open, a section to jump to, a mention to
/// resolve, ...) is entirely the caller's business.
typedef OnActionTap = void Function(String text);

/// Maps [BlockNode] types to the [NodeBuilder] that renders them.
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

  /// Builds one widget per entry of [nodes], in order.
  ///
  /// The builder for each node is looked up by `node.runtimeType` -- an
  /// exact type match, not `is`/subtype matching. A node whose runtime type
  /// isn't a key of this registry (including a subclass of a registered
  /// type) hits the fallback builder, which renders nothing and -- in debug
  /// mode only -- prints a warning via `debugPrint`.
  List<Widget> buildAll(
    BuildContext context,
    List<BlockNode> nodes,
    NaturalBlockTheme theme, [
    OnActionTap? onActionTap,
  ]) {
    return nodes.map((node) {
      final builder = _builders[node.runtimeType] ?? _buildFallback;
      return builder(context, node, theme, this, onActionTap);
    }).toList();
  }

  static Widget _buildFallback(
    BuildContext context,
    BlockNode node,
    NaturalBlockTheme theme,
    NaturalBlockRegistry registry,
    OnActionTap? onActionTap,
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
