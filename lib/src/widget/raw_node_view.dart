import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import 'natural_block_theme.dart';

class RawNodeView extends StatelessWidget {
  final RawNode node;
  final NaturalBlockTheme theme;

  const RawNodeView({super.key, required this.node, required this.theme});

  @override
  Widget build(BuildContext context) {
    final rootStyle = DefaultTextStyle.of(context).style.merge(theme.base);
    final style = theme.styleFor(
      node.decoration,
      baseSize: theme.raw.fontSize ?? rootStyle.fontSize ?? kDefaultFontSize,
    );
    final content = Text.rich(
      TextSpan(
        text: node.text,
        style: rootStyle
            .merge(style)
            .merge(theme.raw)
            .copyWith(fontSize: style.fontSize),
      ),
      // Not the block's alignment: centring each line would undo indentation.
      textAlign: TextAlign.start,
    );

    return Container(
      padding: theme.rawPadding,
      decoration: theme.rawDecoration,
      child: theme.rawScrollsHorizontally
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: content,
            )
          : content,
    );
  }
}
