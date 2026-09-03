import 'package:flutter/widgets.dart';
import 'package:natural_block/natural_block.dart';

import 'natural_block_theme.dart';

class VerbatimNodeView extends StatelessWidget {
  final VerbatimNode node;
  final NaturalBlockTheme theme;

  const VerbatimNodeView({super.key, required this.node, required this.theme});

  @override
  Widget build(BuildContext context) {
    final content = Text.rich(
      TextSpan(
        text: node.text,
        style: DefaultTextStyle.of(context).style.merge(theme.verbatim),
      ),
      softWrap: !theme.verbatimScrollsHorizontally,
    );

    return Container(
      padding: theme.verbatimPadding,
      decoration: theme.verbatimDecoration,
      child: theme.verbatimScrollsHorizontally
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: content,
            )
          : content,
    );
  }
}
