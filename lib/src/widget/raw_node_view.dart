import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import 'natural_block_theme.dart';

class RawNodeView extends StatelessWidget {
  final RawNode node;
  final NaturalBlockTheme theme;

  const RawNodeView({super.key, required this.node, required this.theme});

  @override
  Widget build(BuildContext context) {
    final content = Text.rich(
      TextSpan(
        text: node.text,
        style: DefaultTextStyle.of(context).style.merge(theme.raw),
      ),
      softWrap: !theme.rawScrollsHorizontally,
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
