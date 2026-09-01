// 【解説】[16/16] 利用者から見た入口。最後に読むと全部が繋がる。
// 【解説】
// 【解説】 build() の中身は3行しかない:
// 【解説】   1. パースして ColumnNode を得る       … natural_block 側[9]
// 【解説】   2. registry で子を全部ウィジェットにする … [15][16前半]
// 【解説】   3. ColumnNodeView で縦に積む          … [13]
// 【解説】 ここから [12] TextNodeView まで再帰的に降りていく。
// 【解説】
// 【解説】 build のたびに parse し直している。3000文字で約0.4msと実測済みで、
// 【解説】 実害が出る水準ではないので、あえてメモ化していない。

import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import '../registry/natural_block_registry.dart';
import 'column_node_view.dart';
import 'natural_block_theme.dart';

/// Parses [source] as `natural_block` markup and renders it as Flutter
/// widgets.
///
/// Example:
/// ```dart
/// NaturalBlockView(
///   source: ':!Important Notice:!|Normal text',
/// )
/// ```
class NaturalBlockView extends StatelessWidget {
  /// The `natural_block` markup to parse and render, e.g.
  /// `':!Important Notice:!|Normal text'`. Parsed fresh on every build --
  /// see [NaturalBlockParser].
  final String source;

  /// Styling applied to the parsed nodes: semantic colors, emphasis, and
  /// font-size scaling. Defaults to `const NaturalBlockTheme()`; pass
  /// [NaturalBlockTheme.fromContext] to adapt to the ambient `Theme`, or a
  /// custom instance to override individual styles.
  final NaturalBlockTheme theme;

  /// Maps node types to the widgets that render them. Defaults to
  /// [NaturalBlockRegistry.defaults] (Row/Column/Text support); pass a
  /// registry built with [NaturalBlockRegistry.register] to add or
  /// override node rendering.
  final NaturalBlockRegistry registry;

  /// Called when an actionable span (`TextSpanNode.isAction == true`,
  /// written as `:@...:@` in markup) is tapped, with that span's own
  /// `text`. Left `null` (the default), actionable spans still render with
  /// `NaturalBlockTheme.action` but are not tappable. Neither the parser
  /// nor this package ever opens a URL or otherwise interprets `text` --
  /// deciding what it means is entirely this callback's responsibility.
  final OnActionTap? onActionTap;

  /// Renders an actionable span as something other than styled text -- an
  /// image, a chip, a formatted value.
  ///
  /// Consulted for every actionable span before the default rendering, and
  /// returning `null` for a span leaves that span to the default. Pass
  /// `NaturalBlockImages.builder` to draw the conventional `image(<url>)`
  /// payload as an actual image; note that doing so lets a document fetch
  /// from a third party, which is why nothing here is enabled by default.
  ///
  /// A span this builds owns its own gestures, so [onActionTap] is not
  /// called for it.
  final ActionSpanBuilder? onActionBuild;

  const NaturalBlockView({
    super.key,
    required this.source,
    this.theme = const NaturalBlockTheme(),
    this.registry = NaturalBlockRegistry.defaults,
    this.onActionTap,
    this.onActionBuild,
  });

  @override
  Widget build(BuildContext context) {
    final document = NaturalBlockParser.parse(source);
    final children = registry.buildAll(
      context,
      document.children,
      theme,
      // Flat parameters here, bundled once for the trip down: callers get
      // the ergonomic shape, while every builder in the chain forwards one
      // value instead of a growing list of callbacks.
      NaturalBlockActions(onTap: onActionTap, buildSpan: onActionBuild),
    );

    // No alignment is passed: a DocumentNode is the outermost thing there
    // is, so it has nothing to be aligned within. Alignment belongs to the
    // blocks inside it, each of which carries its own.
    return ColumnNodeView(children: children);
  }
}
