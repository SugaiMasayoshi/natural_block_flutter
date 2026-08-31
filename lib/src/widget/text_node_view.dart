import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import 'natural_block_theme.dart';

/// Renders a [TextNode]'s [TextSpanNode] children as a single [RichText],
/// mapping each span's [SemanticColor], emphasis flag, and `sizeOffset`
/// onto [TextStyle] via [theme].
class TextNodeView extends StatelessWidget {
  /// The node whose [TextNode.children] spans are rendered.
  final TextNode node;

  /// Styling used to turn each span's semantic color, emphasis, and
  /// `sizeOffset` into a concrete [TextStyle].
  final NaturalBlockTheme theme;

  const TextNodeView({super.key, required this.node, required this.theme});

  @override
  Widget build(BuildContext context) {
    final spans = node.children.map((span) {
      final style = theme
          .styleFor(span.color)
          .merge(span.emphasis ? theme.emphasis : null)
          .copyWith(
            fontSize: span.sizeOffset != 0
                ? _fontSizeFor(context, span.sizeOffset)
                : null,
          );
      return TextSpan(text: span.text, style: style);
    }).toList();

    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style.merge(theme.base),
        children: spans,
      ),
    );
  }

  /// Computes the font size for a span with a non-zero [sizeOffset],
  /// scaling from the ambient font size (or [NaturalBlockTheme.baseFontSize]
  /// if there is none) by [NaturalBlockTheme.fontSizeStep] points per step.
  ///
  /// The result is clamped to [NaturalBlockTheme.minFontSize] so a large
  /// negative [sizeOffset] (the parser supports e.g. `:-----`, an offset of
  /// -5) cannot drive the font size to zero or below, which Flutter's
  /// [TextStyle] asserts against.
  double _fontSizeFor(BuildContext context, int sizeOffset) {
    final ambient =
        DefaultTextStyle.of(context).style.fontSize ?? theme.baseFontSize;
    final scaled = ambient + sizeOffset * theme.fontSizeStep;
    return scaled < theme.minFontSize ? theme.minFontSize : scaled;
  }
}
