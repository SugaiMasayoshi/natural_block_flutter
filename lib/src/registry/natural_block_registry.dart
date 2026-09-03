import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../widget/natural_block_theme.dart';
import 'default_builders.dart';

typedef NodeBuilder = Widget Function(
  BuildContext context,
  BlockNode node,
  NaturalBlockTheme theme,
  NaturalBlockRegistry registry,
  NaturalBlockActions actions,
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NaturalBlockActions &&
        onTap == other.onTap &&
        buildSpan == other.buildSpan;
  }

  @override
  int get hashCode => Object.hash(onTap, buildSpan);
}

class NaturalBlockRegistry {
  final Map<Type, NodeBuilder> _builders;

  const NaturalBlockRegistry._(this._builders);

  static const Map<Type, NodeBuilder> _defaultBuilders = {
    RowNode: buildRowNode,
    TableNode: buildTableNode,
    ColumnNode: buildColumnNode,
    TextNode: buildTextNode,
  };

  static const NaturalBlockRegistry defaults = NaturalBlockRegistry._(
    _defaultBuilders,
  );

  const NaturalBlockRegistry.empty() : _builders = const {};

  NaturalBlockRegistry register(Type type, NodeBuilder builder) =>
      NaturalBlockRegistry._({..._builders, type: builder});

  NaturalBlockRegistry registerAll(Map<Type, NodeBuilder> builders) =>
      NaturalBlockRegistry._({..._builders, ...builders});

  List<Widget> buildAll(
    BuildContext context,
    List<BlockNode> nodes,
    NaturalBlockTheme theme, [
    NaturalBlockActions actions = NaturalBlockActions.none,
  ]) {
    return nodes.map((node) {
      final builder = _builders[node.runtimeType] ?? _buildFallback;
      return builder(context, node, theme, this, actions);
    }).toList();
  }

  static Widget _buildFallback(
    BuildContext context,
    BlockNode node,
    NaturalBlockTheme theme,
    NaturalBlockRegistry registry,
    NaturalBlockActions actions,
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
